from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse
import os
from ..config import settings
import mimetypes

router = APIRouter(prefix="/files", tags=["Files"])


@router.get("/{path:path}")
def stream_file(request: Request, path: str):
    file_path = os.path.join(settings.UPLOAD_DIR, path)

    if not os.path.exists(file_path) or not os.path.isfile(file_path):
        raise HTTPException(status_code=404, detail="File not found")

    file_size = os.path.getsize(file_path)
    range_header = request.headers.get("range")

    start = 0
    end = file_size - 1

    if range_header:
        range_value = range_header.replace("bytes=", "")
        parts = range_value.split("-")

        start = int(parts[0]) if parts[0] else 0
        end = int(parts[1]) if len(parts) > 1 and parts[1] else file_size - 1

    def iterfile():
        with open(file_path, "rb") as f:
            f.seek(start)
            chunk_size = 1024 * 1024  # 1MB

            bytes_remaining = end - start + 1

            while bytes_remaining > 0:
                chunk = f.read(min(chunk_size, bytes_remaining))
                if not chunk:
                    break
                bytes_remaining -= len(chunk)
                yield chunk

    mime_type, _ = mimetypes.guess_type(file_path)

    headers = {
        "Accept-Ranges": "bytes",
        "Content-Type": mime_type or "application/octet-stream",
    }

    if range_header:
        headers.update({
            "Content-Range": f"bytes {start}-{end}/{file_size}",
            "Content-Length": str(end - start + 1),
        })
        return StreamingResponse(iterfile(), status_code=206, headers=headers)

    else:
        headers["Content-Length"] = str(file_size)
        return StreamingResponse(iterfile(), status_code=200, headers=headers)

