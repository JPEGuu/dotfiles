import importlib.machinery
import importlib.util
import io
import json
import os
import subprocess
import sys
import time
import unittest
from contextlib import redirect_stderr, redirect_stdout
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path
from unittest import mock


os.environ["TZ"] = "UTC"
if hasattr(time, "tzset"):
    time.tzset()


def load_twrep():
    path = Path(__file__).with_name("twrep")
    loader = importlib.machinery.SourceFileLoader("twrep", str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def fixed_now():
    return datetime(2026, 8, 1, 12, 0, tzinfo=timezone.utc)


def iv(id_, start, end, tags):
    data = {"id": id_, "start": start, "tags": tags}
    if end is not None:
        data["end"] = end
    return data


class TwrepTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.twrep = load_twrep()

    def test_t1_basic_project_tree_tag_breakdown_and_vertical_total(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T093000Z", [
                "description:CSVのカラム仕様を確認する",
                "project:自社システム.CSV出力機能",
                "tag:コーディング",
            ]),
            iv(2, "20260801T093000Z", "20260801T094500Z", [
                "description:追加確認",
                "project:自社システム",
            ]),
            iv(3, "20260801T100000Z", "20260801T103000Z", [
                "description:分類なし",
                "tag:調査",
            ]),
        ]

        expected = "\n".join([
            "・自社システム（0.75h）",
            "　・CSV出力機能（0.50h）",
            "　　・コーディング（0.50h）",
            "　・（タグ無し）（0.25h）",
            "",
            "・未分類（0.50h）",
            "　・調査（0.50h）",
            "",
            "合計 1.25h",
            "未分類が 1 件あります。tfix で修正できます。",
        ])

        self.assertEqual(expected, self.twrep.build_report(intervals, fixed_now()))

    def test_t2_round_quarter_boundaries(self):
        self.assertEqual(Decimal("0.25"), self.twrep.round_q(7 * 60 + 30))
        self.assertEqual(Decimal("0.50"), self.twrep.round_q(22 * 60 + 30))

    def test_t3_parent_totals_are_sum_of_rounded_leaves(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T090800Z", ["project:P", "tag:設計"]),
            iv(2, "20260801T091000Z", "20260801T091800Z", ["project:P", "tag:調査"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("・P（0.50h）", report)
        self.assertIn("　・設計（0.25h）", report)
        self.assertIn("　・調査（0.25h）", report)
        self.assertIn("合計 0.50h", report)

    def test_t4_variable_project_depth(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T100000Z", ["project:A", "tag:設計"]),
            iv(2, "20260801T100000Z", "20260801T110000Z", ["project:B.C.D", "tag:調査"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("・A（1.00h）", report)
        self.assertIn("　・設計（1.00h）", report)
        self.assertIn("・B（1.00h）", report)
        self.assertIn("　・C（1.00h）", report)
        self.assertIn("　　・D（1.00h）", report)
        self.assertIn("　　　・調査（1.00h）", report)

    def test_t5_missing_project_becomes_unclassified(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T091500Z", ["description:調べる", "tag:調査"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("・未分類（0.25h）", report)
        self.assertIn("　・調査（0.25h）", report)
        self.assertIn("合計 0.25h", report)

    def test_t6_missing_tag_becomes_no_tag_leaf(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T091500Z", ["description:分類なし", "project:P"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("・P（0.25h）", report)
        self.assertIn("　・（タグ無し）（0.25h）", report)
        self.assertNotIn("未分類が", report)

    def test_t7_unlabeled_timew_tags_are_unclassified_and_displayed_raw(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T093000Z", ["manual", "foo:bar"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("・未分類（0.50h）", report)
        self.assertIn("　・manual / foo:bar（0.50h）", report)

    def test_t8_running_interval_uses_now(self):
        now = datetime(2026, 8, 1, 10, 30, tzinfo=timezone.utc)
        intervals = [
            iv(1, "20260801T100000Z", None, ["project:P", "tag:コーディング"]),
        ]

        self.assertIn("　・コーディング（0.50h）", self.twrep.build_report(intervals, now))

    def test_t9_sort_by_earliest_start_at_each_level(self):
        intervals = [
            iv(1, "20260801T110000Z", "20260801T120000Z", ["project:B.後", "tag:調査"]),
            iv(2, "20260801T090000Z", "20260801T100000Z", ["project:A.先", "tag:設計"]),
            iv(3, "20260801T103000Z", "20260801T110000Z", ["project:A.後", "tag:単体テスト"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertLess(report.index("・A（1.50h）"), report.index("・B（1.00h）"))
        self.assertLess(report.index("　・先（1.00h）"), report.index("　・後（0.50h）"))

    def test_t10_zero_hour_leaf_is_not_removed(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T090100Z", ["project:P", "tag:その他"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("　・その他（0.00h）", report)
        self.assertIn("合計 0.00h", report)

    def test_t11_project_filter_matches_prefix_with_dot_boundary(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T100000Z", ["project:A", "tag:設計"]),
            iv(2, "20260801T100000Z", "20260801T110000Z", ["project:A.B", "tag:調査"]),
            iv(3, "20260801T110000Z", "20260801T120000Z", ["project:AB", "tag:その他"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now(), project="A")

        self.assertIn("・A（2.00h）", report)
        self.assertIn("　・B（1.00h）", report)
        self.assertNotIn("・AB", report)
        self.assertIn("合計 2.00h", report)

    def test_t12_tag_filter(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T100000Z", ["project:P", "tag:設計"]),
            iv(2, "20260801T100000Z", "20260801T110000Z", ["project:P", "tag:調査"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now(), tag="調査")

        self.assertNotIn("設計", report)
        self.assertIn("　・調査（1.00h）", report)
        self.assertIn("合計 1.00h", report)

    def test_t13_multiple_tag_uses_last_and_warns_in_cli(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T100000Z", ["project:P", "tag:設計", "tag:調査"]),
        ]
        stdin = io.StringIO(json.dumps(intervals, ensure_ascii=False))
        stderr = io.StringIO()
        stdout = io.StringIO()

        with mock.patch.object(sys, "stdin", stdin), redirect_stderr(stderr), redirect_stdout(stdout):
            code = self.twrep.main([":day"])

        self.assertEqual(0, code)
        self.assertIn("tag: が複数あります", stderr.getvalue())
        self.assertIn("　・調査（1.00h）", stdout.getvalue())

    def test_t14_description_colon_does_not_join_aggregation(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T100000Z", [
                "description:API: CSV",
                "project:P",
                "tag:設計",
            ]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("・P（1.00h）", report)
        self.assertNotIn("API", report)

    def test_t15_empty_input(self):
        self.assertEqual("合計 0.00h", self.twrep.build_report([], fixed_now()))

    def test_t16_list_unclassified_format(self):
        intervals = [
            iv(42, "20260801T090000Z", "20260801T093000Z", [
                "description:手動",
                "tag:調査",
                "manual",
            ]),
        ]

        self.assertEqual(
            ["42\t2026-08-01 09:00-09:30  手動 / 調査 / manual"],
            self.twrep.build_unclassified(intervals),
        )

    def test_stdin_json_is_used_by_cli(self):
        intervals = [iv(1, "20260801T090000Z", "20260801T100000Z", ["project:P", "tag:設計"])]
        stdin = io.StringIO(json.dumps(intervals, ensure_ascii=False))
        stdout = io.StringIO()

        with (
            mock.patch.object(sys, "stdin", stdin),
            mock.patch.object(self.twrep.subprocess, "run") as mocked_run,
            redirect_stdout(stdout),
        ):
            code = self.twrep.main([":day"])

        self.assertEqual(0, code)
        mocked_run.assert_not_called()
        self.assertIn("・P（1.00h）", stdout.getvalue())

    def test_timew_nonzero_exit_code_is_propagated(self):
        exc = subprocess.CalledProcessError(3, ["timew"], stderr="timew failed\n")

        with mock.patch.object(self.twrep, "load_intervals", side_effect=exc):
            stderr = io.StringIO()
            with redirect_stderr(stderr):
                code = self.twrep.main([":day"])

        self.assertEqual(3, code)
        self.assertEqual("timew failed\n", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
