//
//  PayWallHighView.swift
//  NoLet
//
//  Created by lynn on 2025/5/15.
//

import SwiftUI
import StoreKit

/// IAP View Images
enum IAPImage: String, CaseIterable {
    /// Raw value represents the asset image
    case one = "IAP1"
    case two = "IAP2"
    case three = "IAP3"
    case four = "IAP4"
}

@available(iOS 17.0, *)
struct PayWallHighView: View {
    @EnvironmentObject private var manager:AppManager
    @State private var loadingStatus: (Bool, Bool) = (false, false)
    
    var isLoadingCompleted: Bool {
        loadingStatus.0 && loadingStatus.1
    }
    
    var groupIds:[String]{ StoreProduct.group.ids }
    
    var body: some View {
        VStack(spacing: 0) {
            SubscriptionStoreView(productIDs: groupIds, marketingContent: {
                CustomMarketingView()
            })
            .diff{ view in
                Group{
                    if #available(iOS 18.0, *){
                        view
                            .subscriptionStoreControlStyle(
                                .pagedProminentPicker,
                                placement: .automatic )
                    }else{
                        view
                    }
                }
            }
            .subscriptionStorePickerItemBackground(.ultraThinMaterial)
            .storeButton(.visible, for: .restorePurchases)
            .subscriptionStorePolicyDestination(url: URL(string: BaseConfig.privacyURL)!, for: .privacyPolicy)
            .subscriptionStorePolicyDestination(url: URL(string: BaseConfig.userAgreement)!, for: .termsOfService)
            .onInAppPurchaseStart { product in
                NLog.log(" Show Loading Screen Purchasing \(product.displayName)")
            }
            .subscriptionStatusTask(for: StoreProduct.groupIds) { _ in
               loadingStatus.1 = true
            }
            .onInAppPurchaseCompletion { product, result in
                switch result {
                case .success(let result):
                    switch result {
                    case .success(let result):
                        if case .verified(let transaction) = result{
                            Task{@MainActor in
                                await transaction.finish()
                                manager.sheetPage = .none
                            }
                            NLog.log("Success and verify purchase using verification result")
                        }
                    case .pending:
                        NLog.log("Pending Action")
                    case .userCancelled:
                        NLog.log("User Cancelled")
                    @unknown default:
                        fatalError()
                    }
                case .failure(let error):
                    NLog.error(error.localizedDescription)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(isLoadingCompleted ? 1 : 0)
        .background(
            BackdropView().ignoresSafeArea(.all, edges: .bottom)
        )
        .overlay {
            if !isLoadingCompleted {
                ProgressView()
                    .font(.largeTitle)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isLoadingCompleted)
        .storeProductsTask(for: groupIds) { @MainActor collection in
            
            if let products = collection.products, products.count == groupIds.count {
                try? await Task.sleep(for: .seconds(0.1))
                loadingStatus.0 = true
            }
        }
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
    }
    
   
    
    /// Backdrop View
    @ViewBuilder
    func BackdropView() -> some View {
        GeometryReader {
            let size = $0.size
            
            /// This is a Dark image, but you can use your own image as per your needs!
            Image("IAP4")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .scaleEffect(1.5)
                .blur(radius: 70, opaque: true)
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.2))
                }
                .ignoresSafeArea()
        }
    }
    
    /// Custom Marketing View (Header View)
    @ViewBuilder
    func CustomMarketingView() -> some View {
        ZStack {
            /// App Screenshots View
            HStack(spacing: 25) {
                ScreenshotsView([.one, .two, .three], offset: -200)
                ScreenshotsView([.four, .one, .two], offset: -350)
                ScreenshotsView([.two, .three, .one], offset: -250)
                    .overlay(alignment: .trailing) {
                        ScreenshotsView([.four, .two, .one], offset: -150)
                            .visualEffect { content, proxy in
                                content
                                    .offset(x: proxy.size.width + 25)
                            }
                    }
            }
            .frame(maxHeight: .infinity)
            .offset(x: 20)
            /// Progress Blur Mask
            .mask {
                LinearGradient(colors: [
                    .white,
                    .white.opacity(0.9),
                    .white.opacity(0.7),
                    .white.opacity(0.4),
                    .clear
                ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .padding(.bottom, -100)

            }

            /// Replace with your App Information
            VStack(spacing: 6) {

                Text(BaseConfig.AppName)
                    .font(.largeTitle.bold())
                
                
                Text(String(localized: "本App免费使用,赞助不会开启任何新功能") )
                .font(.callout)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top)
            }
            .foregroundStyle(.white)
            .shadow(color: .black, radius: 10, x: 0, y: 10)
            .padding(.horizontal, 15)
        }
    }
    
    @ViewBuilder
    func ScreenshotsView(_ content: [IAPImage], offset: CGFloat) -> some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                ForEach(content.indices, id: \.self) { index in
                    Image(content[index].rawValue)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .offset(y: offset)
        }
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
        .rotationEffect(.init(degrees: -30), anchor: .bottom)
        .scrollClipDisabled()
    }
}

@available(iOS 17.0, *)
#Preview {
    PayWallHighView()
        .environmentObject(AppManager.shared)
        .sheet(isPresented: .constant(true)) {
            PayWallHighView()
                .environmentObject(AppManager.shared)
        }
}

enum StoreProduct{
    case one
    case group
    case all
    
    static let groupIds = "21582431"
    static let once = "one_time_support_2_99"
    static let monthly = "pushback_monthly_18_intro7days_free"
    static let yearly = "pushback_yearly_128_intro7days_free"
    
    var ids:[String]{
        switch self {
        case .one: [Self.once]
        case .group: [Self.monthly, Self.yearly]
        case .all:[Self.once, Self.monthly, Self.yearly]
        }
    }
}
