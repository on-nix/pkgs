import brotli
import contextlib
import http.client
import json
import random
from typing import (
    Any,
    Dict,
    List,
)
import urllib.request


def hydra_ls_as_list(data: Dict[str, Any]) -> List[str]:
    def recurse(data, prefix) -> List[str]:
        elements = []
        if data["type"] == "directory":
            for entry in data["entries"]:
                elements.extend(
                    recurse(data["entries"][entry], f"{prefix}/{entry}")
                )
        elif data["type"] == "regular":
            elements.append(prefix)
        elif data["type"] == "symlink":
            elements.append(prefix)
        else:
            raise NotImplementedError(data["type"])

        return elements

    return recurse(data["root"], "")


@contextlib.contextmanager
def fetch(url: str) -> http.client.HTTPResponse:
    request = urllib.request.Request(
        url, headers=dict(accept="application/json")
    )

    with urllib.request.urlopen(request) as response:
        yield response


@contextlib.contextmanager
def fetch_json(url: str) -> Dict[str, Any]:
    with fetch(url) as response:
        response_content = response.read()
        if response.headers.get("Content-Encoding") == "br":
            response_content = brotli.decompress(response_content)
        yield json.loads(response_content)


def main() -> None:
    with open("data/nixpkgs/attrs.json", encoding="utf-8") as file:
        attrs: List[str] = json.load(file)

    # Process 100 randomly
    random.shuffle(attrs)
    for attr in ["firefox", "nix"] + attrs[0:100]:
        print(attr)
        try:
            url: str = f"https://hydra.nixos.org/job/nixpkgs/trunk/{attr}.x86_64-linux/latest-finished"

            ls: Dict[str, List[str]] = {}
            print("-", url)
            with fetch_json(url) as data:
                for output, output_data in data["buildoutputs"].items():
                    digest = output_data["path"][11:43]
                    url = f"https://cache.nixos.org/{digest}.ls"
                    print("-", output, url)
                    with fetch_json(url) as data:
                        ls[output] = hydra_ls_as_list(data)

            attr_path: str = f"data/nixpkgs/outputs/{attr}.json"
            with open(attr_path, encoding="utf-8", mode="w") as file:
                json.dump(ls, file, indent=2, sort_keys=True)

        except urllib.error.HTTPError:
            print("-", "error")


if __name__ == "__main__":
    main()
