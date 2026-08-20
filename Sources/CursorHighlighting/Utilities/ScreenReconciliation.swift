struct ScreenReconciliation<ID: Hashable> {
    let added: Set<ID>
    let removed: Set<ID>
    let retained: Set<ID>

    init(existing: Set<ID>, current: Set<ID>) {
        added = current.subtracting(existing)
        removed = existing.subtracting(current)
        retained = existing.intersection(current)
    }
}
