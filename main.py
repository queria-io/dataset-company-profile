"""公開データを法人番号で束ねた企業カルテを作る。"""

import logging

from dbt.cli.main import dbtRunner

logging.basicConfig(level=logging.INFO, format="%(message)s", force=True)


def main():
    dbt = dbtRunner()
    for args in (["deps"], ["build"], ["docs", "generate"]):
        if not dbt.invoke(args).success:
            raise SystemExit(f"dbt {args[0]} failed")


if __name__ == "__main__":
    main()
