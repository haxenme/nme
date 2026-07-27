// IosStoreKit2.swift
// StoreKit 2 implementation for NME's BillingManager.
// Entry points are exposed with C linkage via @_silgen_name so that
// IosStore.mm (compiled by hxcpp) can forward-declare and call them directly.

import StoreKit

// ---------------------------------------------------------------------------
// C entry points called from IosStore.mm
// ---------------------------------------------------------------------------

@_silgen_name("nme_swift_init_store")
public func swiftInitStore() {
    Task { await NmeStore.shared.startTransactionListener() }
}

@_silgen_name("nme_swift_query_products")
public func swiftQueryProducts(_ ptrs: UnsafePointer<UnsafePointer<CChar>?>, _ count: Int32) {
    let skus = (0..<Int(count)).compactMap { ptrs[$0].map { String(cString: $0) } }
    Task { await NmeStore.shared.queryProducts(skus) }
}

@_silgen_name("nme_swift_purchase")
public func swiftPurchase(_ sku: UnsafePointer<CChar>) {
    let id = String(cString: sku)
    Task { await NmeStore.shared.purchase(id) }
}

@_silgen_name("nme_swift_restore")
public func swiftRestore() {
    Task { await NmeStore.shared.restore() }
}

// ---------------------------------------------------------------------------
// Store logic
// ---------------------------------------------------------------------------

@MainActor
class NmeStore {
    static let shared = NmeStore()
    private var products: [Product] = []
    private var listenerTask: Task<Void, Never>?

    // Start listening for transaction updates (including cross-device restores).
    func startTransactionListener() async {
        listenerTask?.cancel()
        listenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleResult(result)
            }
        }
        // Deliver any already-verified entitlements on startup.
        for await result in Transaction.currentEntitlements {
            await handleResult(result)
        }
    }

    private func handleResult(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let tx) = result else { return }
        nme_store_on_purchase(tx.productID, true, false)
        await tx.finish()
    }

    func queryProducts(_ ids: [String]) async {
        do {
            let fetched = try await Product.products(for: Set(ids))
            products = fetched
            for p in fetched {
                let period = subscriptionPeriodString(p.subscription?.subscriptionPeriod)
                nme_store_add_sku_detail(p.id, p.displayName, p.description,
                                         p.displayPrice, period)
            }
        } catch {
            // Return empty list on error; Haxe side will get SkuDetailsUpdated(false)
            // if no products were sent before nme_store_on_sku_done.
        }
        nme_store_on_sku_done()
    }

    func purchase(_ sku: String) async {
        guard let product = products.first(where: { $0.id == sku }) else {
            nme_store_on_purchase(sku, false, false)
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    nme_store_on_purchase(sku, true, false)
                    await tx.finish()
                } else {
                    nme_store_on_purchase(sku, false, false)
                }
            case .pending:
                nme_store_on_purchase(sku, true, true)
            case .userCancelled:
                nme_store_on_purchase(sku, false, false)
            @unknown default:
                nme_store_on_purchase(sku, false, false)
            }
        } catch {
            nme_store_on_purchase(sku, false, false)
        }
    }

    func restore() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result {
                nme_store_on_purchase(tx.productID, true, false)
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

private func subscriptionPeriodString(_ period: Product.SubscriptionPeriod?) -> String {
    guard let period = period else { return "" }
    let unit: String
    switch period.unit {
    case .day:   unit = "D"
    case .week:  unit = "W"
    case .month: unit = "M"
    case .year:  unit = "Y"
    @unknown default: unit = "M"
    }
    return "P\(period.value)\(unit)"  // ISO 8601 duration e.g. "P1M", "P1Y"
}
