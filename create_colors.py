import os
import json

base_path = "/Users/master/Documents/Xcode Files/CODElonize/Assets/Assets.xcassets"

colors = {
    "ThemeTeal": "#0A6E82",
    "ThemeOrange": "#F29900",
    "ThemeCream": "#EBE0C5",
    "ThemeDarkTeal": "#064857"
}

def hex_to_rgb(hex_code):
    hex_code = hex_code.lstrip('#')
    return tuple(int(hex_code[i:i+2], 16) for i in (0, 2, 4))

for name, hex_code in colors.items():
    folder_path = os.path.join(base_path, f"{name}.colorset")
    os.makedirs(folder_path, exist_ok=True)
    r, g, b = hex_to_rgb(hex_code)
    
    contents = {
        "colors": [
            {
                "color": {
                    "color-space": "srgb",
                    "components": {
                        "alpha": "1.000",
                        "blue": f"0x{hex_code[5:7]}",
                        "green": f"0x{hex_code[3:5]}",
                        "red": f"0x{hex_code[1:3]}"
                    }
                },
                "idiom": "universal"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    with open(os.path.join(folder_path, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=4)

print("Colors created.")
