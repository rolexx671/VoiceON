#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Создаёт локальный запускатель из настоящих синхронных методов XCTest."""
import re
import sys
from pathlib import Path

repository, destination = map(Path, sys.argv[1:])
excluded = {"ModelAvailabilityTests.swift"}
runner = ["import Foundation", "@main struct LocalTestRunner {", "static func main() {"]
test_count = 0
suite_count = 0
for path in sorted((repository / "Tests/OpenWisprTests").glob("*Tests.swift")):
    if path.name in excluded:
        print(f"Пропущен сетевой тест: {path.name}", flush=True)
        continue
    source = path.read_text(encoding="utf-8")
    classes = re.findall(r"\bfinal class (\w+): XCTestCase", source)
    methods = re.findall(r"(?m)^\s+func (test\w+)\(\)\s*(throws\s*)?\{", source)
    declarations = re.findall(r"\bfunc\s+test\w+", source)
    if len(classes) != 1 or not methods or len(methods) != len(declarations):
        raise SystemExit(f"Неподдерживаемый формат тестов: {path}. Используйте swift test с Xcode.")
    if re.search(r"\b(expectation|waitForExpectations|XCTSkip|XCTWaiter)\b|@MainActor", source):
        raise SystemExit(f"В {path} нужен настоящий XCTest. Используйте swift test с Xcode.")
    class_name = classes[0]
    transformed = source.replace("import XCTest", "import Foundation").replace("@testable import OpenWisprLib", "")
    (destination / path.name).write_text(transformed, encoding="utf-8")
    for name, throwing in methods:
        invocation = ("try " if throwing else "") + f"test.{name}()"
        runner.append(f'runLocalTest("{class_name}.{name}", make: {{ {class_name}() }}) {{ test in {invocation} }}')
    runner.append(f'print("Проверено: {class_name} ({len(methods)} тестов)")')
    test_count += len(methods)
    suite_count += 1
runner += [
    f'print("Выполнено {test_count} тестов в {suite_count} наборах; утверждений: \\(LocalTestReport.assertions); ошибок: \\(LocalTestReport.failures).")',
    "exit(LocalTestReport.failures == 0 ? 0 : 1)",
    "}}",
]
(destination / "Runner.swift").write_text("\n".join(runner) + "\n", encoding="utf-8")
print(f"Подготовлено: {test_count} синхронных тестов. Проверки HTTP выполняются отдельно через XCTest.", flush=True)
