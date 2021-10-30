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
                    attrs.setdefault(attr, dict(versions={}))
                    attrs[attr]["versions"].setdefault(version, [])
                    if len(attrs[attr]["versions"][version]) < 2:
                        attrs[attr]["versions"][version].append(commit)
                    else:
                        attrs[attr]["versions"][version][-1] = commit

    attrs_path: str = "data/nixpkgs/attrs.json"
    with open(attrs_path, encoding="utf-8", mode="w") as file:
        json.dump(sorted(attrs.keys()), file, indent=2, sort_keys=True)

    for attr, data in attrs.items():
        attr_path: str = f"data/nixpkgs/attrs/{attr}.json"
        with open(attr_path, encoding="utf-8", mode="w") as file:
            json.dump(data, file, indent=2, sort_keys=True)


if __name__ == "__main__":
    main()
