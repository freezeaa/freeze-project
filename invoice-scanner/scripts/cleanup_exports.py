#!/usr/bin/env python3
import argparse
import logging
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
EXPORT_DIR = BASE_DIR / "static" / "exports"
LOG_PATH = BASE_DIR / "scanner.log"
KEEP_LATEST = 20

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(LOG_PATH, encoding="utf-8"),
    ],
)
log = logging.getLogger(__name__)


def list_export_files():
    if not EXPORT_DIR.exists():
        return []
    return sorted(
        [p for p in EXPORT_DIR.iterdir() if p.is_file()],
        key=lambda p: (p.stat().st_mtime, p.name),
        reverse=True,
    )


def cleanup_exports(dry_run: bool = False):
    files = list_export_files()
    keep = files[:KEEP_LATEST]
    delete = files[KEEP_LATEST:]

    log.info(
        "定时清理导出文件开始 | 总数: %d | 保留: %d | 待删除: %d | 模式: %s",
        len(files),
        len(keep),
        len(delete),
        "dry-run" if dry_run else "delete",
    )

    deleted = 0
    failed = 0
    for path in delete:
        try:
            if dry_run:
                log.info("[dry-run] 将删除导出文件 | %s", path.name)
            else:
                path.unlink(missing_ok=True)
                log.info("已删除导出文件 | %s", path.name)
            deleted += 1
        except Exception as e:
            failed += 1
            log.warning("删除导出文件失败 | 文件: %s | 错误: %s", path.name, e)

    log.info(
        "定时清理导出文件结束 | 保留: %d | 删除成功: %d | 删除失败: %d",
        len(keep),
        deleted,
        failed,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Keep latest export files only")
    parser.add_argument("--dry-run", action="store_true", help="Only log what would be deleted")
    args = parser.parse_args()
    cleanup_exports(dry_run=args.dry_run)
