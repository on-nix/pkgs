from glob import (
    iglob,
)
import json
import os
from typing import (
    Any,
    Dict,
    List,
    Set,
)


def load(path: str) -> Any:
    with open(path, encoding="utf-8") as file:
        return json.load(file)


def main() -> None:
    commits: List[str] = load("data/nixpkgs/commits.json")

    # Find the latest commit for which we have data available
    for commit in commits:
        commit_data_path: str = f"data/nixpkgs/commits/{commit}.json"
        if os.path.exists(commit_data_path):
            commit_data: Dict[str, str] = load(commit_data_path)
            break

    # Create a mapping of attributes to metadata
    attr_names: Set[str] = set(commit_data)
    attrs: Dict[str, Any] = {}
    for commit_index, commit in enumerate(commits):
        print(commit_index, commit)
        commit_data_path = f"data/nixpkgs/commits/{commit}.json"
        if os.path.exists(commit_data_path):
            commit_data = load(commit_data_path)

            for attr, version in commit_data.items():
                if attr in attr_names:
                    attrs.setdefault(attr, dict(versions=[]))
                    versions = attrs[attr]["versions"]

                    if versions and versions[-1]["name"] == version:
                        versions[-1]["first"] = commit
                    else:
                        versions.append(
                            dict(name=version, last=commit, first=commit)
                        )

    # Append metadata
    meta = load("data/nixpkgs/meta.json")
    for attr, attr_data in attrs.items():
        if attr in meta:
            attr_data["meta"] = meta[attr]

        output_data_path = f"data/nixpkgs/outputs/{attr}.json"
        if os.path.exists(output_data_path):
            attrs[attr]["outputs"] = load(output_data_path)

    # Write attrs index
    attrs_path: str = "data/nixpkgs/attrs.json"
    with open(attrs_path, encoding="utf-8", mode="w") as file:
        json.dump(sorted(attrs.keys()), file, indent=2, sort_keys=True)

    # Write each attr metadata
    for attr, data in attrs.items():
        attr_path: str = f"data/nixpkgs/attrs/{attr}.json"
        with open(attr_path, encoding="utf-8", mode="w") as file:
            json.dump(data, file, indent=2, sort_keys=True)


if __name__ == "__main__":
    main()
