#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove flat background and extract character frames as transparent sprites."
    )
    parser.add_argument("input", type=Path, help="Input sprite sheet PNG")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("animate-source/output/avatar-sprite-sheet.png"),
        help="Output sprite sheet PNG path",
    )
    parser.add_argument(
        "--tolerance",
        type=int,
        default=12,
        help="Background color tolerance per RGB channel",
    )
    parser.add_argument(
        "--padding",
        type=int,
        default=8,
        help="Transparent padding around each frame",
    )
    return parser.parse_args()


def is_background(pixel: tuple[int, int, int, int], bg: tuple[int, int, int, int], tolerance: int) -> bool:
    return all(abs(pixel[i] - bg[i]) <= tolerance for i in range(3))


def remove_background(image: Image.Image, tolerance: int) -> Image.Image:
    rgba = image.convert("RGBA")
    bg = rgba.getpixel((0, 0))
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            pixel = pixels[x, y]
            if is_background(pixel, bg, tolerance):
                pixels[x, y] = (pixel[0], pixel[1], pixel[2], 0)
    return rgba


def find_segments(image: Image.Image) -> list[tuple[int, int]]:
    width, height = image.size
    alpha = image.getchannel("A")
    occupied = []
    for x in range(width):
        has_pixel = any(alpha.getpixel((x, y)) > 0 for y in range(height))
        occupied.append(has_pixel)

    segments: list[tuple[int, int]] = []
    start: int | None = None
    for x, filled in enumerate(occupied):
        if filled and start is None:
            start = x
        elif not filled and start is not None:
            segments.append((start, x - 1))
            start = None
    if start is not None:
        segments.append((start, width - 1))
    return segments


def extract_frames(image: Image.Image) -> list[Image.Image]:
    frames = []
    alpha = image.getchannel("A")
    for left, right in find_segments(image):
        top = None
        bottom = None
        for y in range(image.height):
            if any(alpha.getpixel((x, y)) > 0 for x in range(left, right + 1)):
                top = y
                break
        for y in range(image.height - 1, -1, -1):
            if any(alpha.getpixel((x, y)) > 0 for x in range(left, right + 1)):
                bottom = y
                break
        if top is None or bottom is None:
            continue
        frames.append(image.crop((left, top, right + 1, bottom + 1)))
    return frames


def pad_frames(frames: list[Image.Image], padding: int) -> list[Image.Image]:
    max_width = max(frame.width for frame in frames)
    max_height = max(frame.height for frame in frames)
    canvas_width = max_width + padding * 2
    canvas_height = max_height + padding * 2

    padded = []
    for frame in frames:
        canvas = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
        x = (canvas_width - frame.width) // 2
        y = (canvas_height - frame.height) // 2
        canvas.alpha_composite(frame, (x, y))
        padded.append(canvas)
    return padded


def make_sheet(frames: list[Image.Image]) -> Image.Image:
    frame_width = frames[0].width
    frame_height = frames[0].height
    sheet = Image.new("RGBA", (frame_width * len(frames), frame_height), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * frame_width, 0))
    return sheet


def main() -> None:
    args = parse_args()
    output_path = args.output.resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    cleaned = remove_background(Image.open(args.input), args.tolerance)

    frames = extract_frames(cleaned)
    if not frames:
        raise SystemExit("No visible frames found after background removal.")

    padded_frames = pad_frames(frames, args.padding)
    sheet = make_sheet(padded_frames)
    sheet.save(output_path)

    print(f"Frames: {len(padded_frames)}")
    print(f"Cell size: {padded_frames[0].width}x{padded_frames[0].height}")
    print(f"Output: {output_path}")


if __name__ == "__main__":
    main()
