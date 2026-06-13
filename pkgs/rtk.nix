# rtk (Rust Token Killer) — https://github.com/rtk-ai/rtk
#
# nixpkgs 未収録のため GitHub ソースから buildRustPackage でビルドする。
# 注意: crates.io に同名の別パッケージがあるため、必ずこの GitHub リポジトリを使う。
#
# ⚠️ hash プレースホルダについて:
#   src.hash と cargoHash は lib.fakeHash を置いてある。初回ビルド時に
#   Nix が正しいハッシュをエラーメッセージで提示するので、それを貼り替えること。
#   再現性のため rev は将来固定タグ/コミットへ変更するのが望ましい。
{ lib, rustPlatform, fetchFromGitHub, openssl, pkg-config }:

rustPlatform.buildRustPackage rec {
  pname = "rtk";
  version = "0.9.135";

  src = fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${version}";
    hash = lib.fakeHash; # コンテナ取得値に置換予定
  };

  cargoHash = lib.fakeHash; # コンテナ取得値に置換予定

  # OpenSSL 等に依存する場合の一般的なビルド入力（不要ならビルドエラーで判明する）
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  # ネットワークアクセスを伴うテストが含まれる場合があるため一旦無効化
  doCheck = false;

  meta = with lib; {
    description = "Rust Token Killer — AI CLI のトークン消費を削減するツール";
    homepage = "https://github.com/rtk-ai/rtk";
    license = licenses.mit; # TODO: 実際のライセンスを確認
    mainProgram = "rtk";
  };
}
