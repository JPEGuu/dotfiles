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

    def test_t1_basic_project_tag_description_report(self):
        intervals = [
            iv(1, "20260815T010000Z", "20260815T023000Z", [
                "project:dotfiles",
                "tag:feat",
                "description:timetrack footer",
            ]),
            iv(2, "20260815T030000Z", "20260815T033000Z", [
                "project:dotfiles",
                "tag:fix",
                "description:escape bug",
            ]),
            iv(3, "20260815T040000Z", "20260815T041500Z", [
                "project:work",
                "tag:meeting",
                "description:standup",
            ]),
            iv(4, "20260815T050000Z", "20260815T054500Z", [
                "project:work",
                "tag:review",
                "description:PR #12",
            ]),
        ]

        expected = "\n".join([
            "dotfiles                  2:00  █████████",
            "● feat  timetrack footer  1:30",
            "● fix  escape bug         0:30",
            "",
            "work                      1:00  █████",
            "● meeting  standup        0:15",
            "● review  PR #12          0:45",
            "",
            "合計 3:00",
        ])

        self.assertEqual(expected, self.twrep.build_report(intervals, fixed_now()))

    def test_t2_fmt_hm_rounds_seconds_to_minutes(self):
        self.assertEqual("0:08", self.twrep.fmt_hm(7 * 60 + 30))
        self.assertEqual("0:22", self.twrep.fmt_hm(22 * 60 + 30))
        self.assertFalse(hasattr(self.twrep, "round_q"))

    def test_t3_totals_use_raw_seconds_not_quarter_rounding(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T090800Z", ["project:P", "tag:設計"]),
            iv(2, "20260801T091000Z", "20260801T091800Z", ["project:P", "tag:調査"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertRegex(report, r"(?m)^P\s+0:16  ██████████████$")
        self.assertIn("● 設計  （説明無し）  0:08", report)
        self.assertIn("● 調査  （説明無し）  0:08", report)
        self.assertIn("合計 0:16", report)

    def test_t4_project_is_not_split_by_dot(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T100000Z", ["project:dev.dotfiles", "tag:設計"]),
            iv(2, "20260801T100000Z", "20260801T110000Z", ["project:B.C.D", "tag:調査"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("dev.dotfiles", report)
        self.assertIn("B.C.D", report)
        self.assertNotIn("● C", report)
        self.assertNotIn("● D", report)

    def test_t5_missing_project_becomes_unclassified(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T091500Z", ["description:調べる", "tag:調査"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("未分類", report)
        self.assertIn("● 調査  調べる", report)
        self.assertIn("合計 0:15", report)
        self.assertIn("未分類が 1 件あります。tfix で修正できます。", report)

    def test_t6_missing_tag_uses_fallback_tag(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T091500Z", ["description:分類なし", "project:P"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("● （タグ無し）  分類なし", report)
        self.assertNotIn("未分類が", report)

    def test_t7_missing_description_uses_fallback(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T093000Z", ["manual", "foo:bar"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("未分類", report)
        self.assertIn("● （タグ無し）  （説明無し）", report)

    def test_t8_running_interval_uses_now(self):
        now = datetime(2026, 8, 1, 10, 30, tzinfo=timezone.utc)
        intervals = [
            iv(1, "20260801T100000Z", None, ["project:P", "tag:コーディング"]),
        ]

        report = self.twrep.build_report(intervals, now)
        self.assertIn("● コーディング  （説明無し）  0:30", report)
        self.assertIn("合計 0:30", report)

    def test_t9_sort_by_earliest_start_at_each_level(self):
        intervals = [
            iv(1, "20260801T110000Z", "20260801T120000Z", ["project:B", "tag:後"]),
            iv(2, "20260801T090000Z", "20260801T100000Z", ["project:A", "tag:先"]),
            iv(3, "20260801T103000Z", "20260801T110000Z", ["project:A", "tag:後"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertLess(report.index("A"), report.index("B"))
        self.assertLess(report.index("● 先"), report.index("● 後"))

    def test_t10_zero_second_leaf_is_not_removed(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T090000Z", ["project:P", "tag:その他"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertRegex(report, r"(?m)^P\s+0:00  █$")
        self.assertIn("● その他  （説明無し）  0:00", report)
        self.assertIn("合計 0:00", report)

    def test_t11_project_filter_matches_prefix_with_dot_boundary(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T100000Z", ["project:A", "tag:設計"]),
            iv(2, "20260801T100000Z", "20260801T110000Z", ["project:A.B", "tag:調査"]),
            iv(3, "20260801T110000Z", "20260801T120000Z", ["project:AB", "tag:その他"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now(), project="A")

        self.assertIn("A", report)
        self.assertIn("A.B", report)
        self.assertNotIn("AB", report)
        self.assertIn("合計 2:00", report)

    def test_t12_tag_filter(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T100000Z", ["project:P", "tag:設計"]),
            iv(2, "20260801T100000Z", "20260801T110000Z", ["project:P", "tag:調査"]),
        ]

        report = self.twrep.build_report(intervals, fixed_now(), tag="調査")

        self.assertNotIn("設計", report)
        self.assertIn("● 調査  （説明無し）  1:00", report)
        self.assertIn("合計 1:00", report)

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
        self.assertIn("● 調査  （説明無し）  1:00", stdout.getvalue())

    def test_t14_description_is_leaf_and_may_contain_colon(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T100000Z", [
                "description:API: CSV",
                "project:P",
                "tag:設計",
            ]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertIn("● 設計  API: CSV  1:00", report)

    def test_t15_same_project_tag_description_is_merged(self):
        intervals = [
            iv(1, "20260801T090000Z", "20260801T091000Z", [
                "description:同じ葉",
                "project:P",
                "tag:設計",
            ]),
            iv(2, "20260801T100000Z", "20260801T101000Z", [
                "description:同じ葉",
                "project:P",
                "tag:設計",
            ]),
        ]

        report = self.twrep.build_report(intervals, fixed_now())

        self.assertRegex(report, r"(?m)^P\s+0:20  ██████████████$")
        self.assertEqual(1, report.count("● 設計  同じ葉  0:20"))

    def test_t16_empty_input(self):
        self.assertEqual("合計 0:00", self.twrep.build_report([], fixed_now()))

    def test_t17_list_unclassified_format(self):
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

    def test_t18_stdin_json_is_used_by_cli(self):
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
        self.assertRegex(stdout.getvalue(), r"(?m)^P\s+1:00  ██████████████$")
        self.assertIn("● 設計  （説明無し）  1:00", stdout.getvalue())

    def test_t19_color_flag_controls_ansi_output(self):
        intervals = [iv(1, "20260801T090000Z", "20260801T100000Z", ["project:P", "tag:設計"])]

        plain = self.twrep.build_report(intervals, fixed_now(), color=False)
        colored = self.twrep.build_report(intervals, fixed_now(), color=True)

        self.assertNotIn("\033[38;5;", plain)
        self.assertIn("\033[38;5;2m", colored)
        self.assertIn("\033[0m", colored)

    def test_t20_timew_nonzero_exit_code_is_propagated(self):
        exc = subprocess.CalledProcessError(3, ["timew"], stderr="timew failed\n")

        with mock.patch.object(self.twrep, "load_intervals", side_effect=exc):
            stderr = io.StringIO()
            with redirect_stderr(stderr):
                code = self.twrep.main([":day"])

        self.assertEqual(3, code)
        self.assertEqual("timew failed\n", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
