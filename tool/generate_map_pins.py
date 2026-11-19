"""Generate the three small bitmap pins used by Mapbox point annotations."""

from pathlib import Path

from PIL import Image, ImageDraw


OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "images"
SCALE = 4


def make_pin(name: str, border: str, fill: str, center: str) -> None:
    image = Image.new("RGBA", (72 * SCALE, 92 * SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    def polygon(points, color):
        draw.polygon([(x * SCALE, y * SCALE) for x, y in points], fill=color)

    def ellipse(box, color):
        draw.ellipse(tuple(value * SCALE for value in box), fill=color)

    polygon([(8, 40), (36, 89), (64, 40)], border)
    ellipse((4, 3, 68, 67), border)
    polygon([(13, 41), (36, 80), (59, 41)], fill)
    ellipse((9, 8, 63, 62), fill)
    ellipse((26, 25, 46, 45), center)

    image.resize((72, 92), Image.Resampling.LANCZOS).save(
        OUTPUT / f"map_pin_{name}.png"
    )


make_pin("blue", "#173CCA", "#2959F4", "#FFFFFF")
make_pin("pink", "#8732BB", "#E94A9A", "#FFFFFF")
make_pin("yellow", "#1747E6", "#FFD600", "#121212")
