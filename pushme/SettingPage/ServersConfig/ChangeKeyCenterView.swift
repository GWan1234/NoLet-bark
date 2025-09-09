//
//  ChnageKeyCenterView.swift
//  pushback
//
//  Created by uuneo 2024/10/13.
//


import SwiftUI
import Defaults


struct ChangeKeyCenterView: View {
    @EnvironmentObject private var manager:AppManager
    
    @State private var keyName:String = ""
    @State private var keyHost:String = ""
    
    @State private var disabledPage:Bool = false
    
    var pageTitle:String{
        keyName.isEmpty ? String(localized: "注册KEY") : String(localized: "恢复KEY")
    }
    
    @State private var appear = [false, false, false]
    @State private var circleInitialY:CGFloat = CGFloat.zero
    @State private var circleY:CGFloat = CGFloat.zero
    
    @Default(.servers) var servers
    
    @FocusState private var isPhoneFocused
    @FocusState private var isHostFocused
    
    var serversSelect:[PushServerModel]{
        servers.reduce(into: [PushServerModel]()) { result, item in
            if !result.contains(where: {$0.url == item.url}){
                result.append(item)
            }
        }
    }
    
    var dismiss:() -> Void = {}
    
    @State private var buttonState:AnimatedButton.buttonState = .normal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack{
                Text( pageTitle )
                    .font(.largeTitle).bold()
                    .blendMode(.overlay)
                    .slideFadeIn(show: appear[0], offset: 30)
                
                Spacer()
                
                Button {
                    manager.sheetPage = .scan
                    Haptic.impact()
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .imageScale(.large)
                        .symbolRenderingMode(.palette)
                        .customForegroundStyle(.accent, Color.primary)
                        .symbolEffect(delay: 5)
                        .padding(.trailing, 10)
                }
            }
            
            
            HStack{
                
                Spacer()
                
                
                Menu{
                    ForEach(serversSelect, id: \.id){item in
                        
                        Button{
                            self.keyHost = item.url
                            Haptic.impact()
                        }label:{
                            Text(item.url.removeHTTPPrefix())
                                .minimumScaleFactor(0.5)
                        }
                    }
                }label: {
                    HStack{
                        Image(systemName: "filemenu.and.selection")
                            .imageScale(.medium)
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, .primary)
                        
                        Text("选择服务器")
                        
                        
                    }.padding(.trailing)
                    
                }
                .foregroundColor(.primary)
                .blendMode(.overlay)
            }
            
            
            
            VStack{
                
                InputHost()
                
                InputKey()
                
                
                registerButton()
                    .if(!keyName.isEmpty) { _ in
                        recoverButton()
                    }
                    .transition(.opacity.combined(with: .scale).animation(.easeInOut(duration: 0.5)))
                
                
            }
            .slideFadeIn(show: appear[2], offset: 10)
            
            Divider()
            
            HStack{
                Text( "输入旧key,可以恢复")
                    .font(.footnote.bold())
                    .foregroundColor(.primary.opacity(0.7))
                    .accentColor(.primary.opacity(0.7))
                
                Spacer()
                
                Text( "服务器部署教程")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
                    .onTapGesture {
                        manager.fullPage = .web(BaseConfig.delpoydoc)
                        Haptic.impact()
                    }
                
            }
            
        }
        .coordinateSpace(name: "stack")
        .padding(20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .background(
            VStack {
                Circle().fill(.blue).frame(width: 68, height: 68)
                    .offset(x: 0, y: circleY)
                    .scaleEffect(appear[0] ? 1 : 0.1)
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        )
        .modifier(OutlineModifier(cornerRadius: 30))
        .onAppear { animate() }
        .disabled(disabledPage)
        
        
    }
    
    @ViewBuilder
    func InputHost()-> some View{
        TextField("请输入URL", text: $keyHost)
            .keyboardType(.URL)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .foregroundStyle(.textBlack)
            .customField(
                icon: "personalhotspot.circle"
            ){
                
            }
            .overlay(
                GeometryReader { proxy in
                    let offset = proxy.frame(in: .named("stack")).minY + 32
                    Color.clear.preference(key: CirclePreferenceKey.self, value: offset)
                    
                }.onPreferenceChange(CirclePreferenceKey.self) { value in
                    circleInitialY = value
                    circleY = value
                }
            )
            .focused($isHostFocused)
            .onChange(of: isHostFocused) { value in
                if value {
                    withAnimation {
                        circleY = circleInitialY
                    }
                }
            }
            .onTapGesture {
                self.isHostFocused = true
                Haptic.impact()
            }
    }
    
    @ViewBuilder
    func InputKey()-> some View{
        TextField("请输入旧的KEY", text: $keyName)
            .keyboardType(.default)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .foregroundStyle(.textBlack)
            .customField(
                icon: "person.badge.key"
            )
            .overlay(
                GeometryReader { proxy in
                    let offset = proxy.frame(in: .named("stack")).minY + 32
                    Color.clear.preference(key: CirclePreferenceKey.self, value: offset)
                    
                }.onPreferenceChange(CirclePreferenceKey.self) { value in
                    circleInitialY = value
                    circleY = value
                }
            )
            .focused($isPhoneFocused)
            .onChange(of: isPhoneFocused) { value in
                if value {
                    withAnimation {
                        circleY = circleInitialY
                    }
                }
            }
            .onTapGesture {
                self.isPhoneFocused = true
                Haptic.impact()
            }
    }
    
    @ViewBuilder
    private func recoverButton()-> some View{
        VStack{
            
            
            AnimatedButton(state:$buttonState,
                           normal:
                    .init(title: String(localized: "恢复KEY"), background: .blue,symbolImage: "pencil.circle"),
                           success:
                    .init(title: String(localized: "恢复成功"), background: .green,symbolImage: "checkmark.circle"),
                           fail:
                    .init(title: String(localized: "恢复失败"), background: .red,symbolImage: "xmark.circle"),
                           loadings: [
                            .init(title: String(localized: "检查参数..."), background: .cyan),
                            .init(title: String(localized: "恢复中..."),background: .cyan)
                           ]
            ) { view in
                
                 DispatchQueue.main.async {
                    self.disabledPage = true
                }
                await view.next(.loading(0))
                
                 DispatchQueue.main.async {
                    self.keyName = self.keyName.trimmingSpaceAndNewLines
                    self.keyHost = self.keyHost.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                try? await Task.sleep(for: .seconds(0.5))
                
                
                guard keyHost.hasHttp(), !keyName.isEmpty else {
                    await view.next(.fail)
                    Toast.info(title: "参数错误")
                     DispatchQueue.main.async {
                        self.disabledPage = false
                    }
                    return
                }
                
                
                
                await view.next(.loading(1))
                
                
                
                let success = await manager.restore(address: keyHost, deviceKey: self.keyName)
                
                if success{
                    try? await Task.sleep(for: .seconds(1))
                    await view.next(.success){
                         DispatchQueue.main.async{
                            self.dismiss()
                            self.disabledPage = false
                        }
                    }
                }else {
                    Toast.error(title: "key不正确")
                    await view.next(.fail)
                    self.disabledPage = false
                }
            }
            
        }.padding(.top)
        
    }
    
    @ViewBuilder
    private func registerButton()-> some View{
        VStack{
            
            
            AnimatedButton(  state: $buttonState, normal:
                    .init(title: String(localized: "注册KEY"),background: .blue,symbolImage: "person.crop.square.filled.and.at.rectangle"), success:
                    .init(title: String(localized: "注册成功"), background: .green,symbolImage: "checkmark.circle"), fail:
                    .init(title: String(localized: "注册失败"),background: .red,symbolImage: "xmark.circle"), loadings: [
                        .init(title: String(localized: "检查参数..."), background: .cyan),
                        .init(title: String(localized: "注册中..."), background: .cyan)
                    ]
            ) { view in
                
                self.disabledPage = true
                self.buttonState = .loading(0)
                try? await Task.sleep(for: .seconds(0.5))
                
                guard keyHost.count > 3 && keyHost.hasHttp() else {
                    Toast.error(title: "格式错误")
                    await view.next(.fail)
                     DispatchQueue.main.async {
                        self.disabledPage = false
                    }
                    return
                }
                
                await view.next(.loading(1))
                
                
                let item = PushServerModel(url: keyHost)
                let success = await manager.appendServer(server: item)
                if success{
                    
                    try? await Task.sleep(for: .seconds(1))
                    await view.next(.success){
                         DispatchQueue.main.async{
                            self.dismiss()
                            self.disabledPage = false
                        }
                    }
                    
                    
                }else {
                    await view.next(.fail)
                     DispatchQueue.main.async {
                        self.disabledPage = false
                    }
                }
                
            }
            
        }.padding(.top)
        
    }
    
    
    func animate() {
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.2)) {
            appear[0] = true
        }
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.4)) {
            appear[1] = true
        }
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.6)) {
            appear[2] = true
        }
    }
    
}

struct ChangeKeyView: View {
    @EnvironmentObject private var manager:AppManager
    
    @State var appear = false
    @State var appearBackground = false
    @State var viewState = CGSize.zero
    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                viewState = value.translation
            }
            .onEnded { value in
                if value.translation.height > 300 {
                    dismissModal()
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        viewState = .zero
                        self.hideKeyboard()
                    }
                }
            }
    }
    
    var body: some View {
        ZStack {
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(appear ? 1 : 0)
                .ignoresSafeArea()
            
            GeometryReader { proxy in
                ChangeKeyCenterView(dismiss: dismissModal)
                    .rotationEffect(.degrees(viewState.width / 40))
                    .rotation3DEffect(.degrees(viewState.height / 20), axis: (x: 1, y: 0, z: 0), perspective: 1)
                    .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 30)
                    .padding(20)
                    .offset(x: viewState.width, y: viewState.height)
                    .gesture(drag)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .offset(y: appear ? 0 : proxy.size.height)
                    .background(
                        Image("Blob 1").offset(x: 170, y: -60)
                            .opacity(appearBackground ? 1 : 0)
                            .offset(y: appearBackground ? -10 : 0)
                            .blur(radius: appearBackground ? 0 : 40)
                            .hueRotation(.degrees(viewState.width / 5))
                    )
            }.frame(maxWidth: ISPAD ? minSize / 2 : .infinity)
            
            VStack{
                HStack{
                    Spacer()
                    Button {
                        dismissModal()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding()
                    .offset(x: appear ? 0 : 100)
                }
                Spacer()
            }
            
            
            
           
            
            
        }
        
        
        .onAppear {
            withAnimation(.spring()) {
                appear = true
            }
            withAnimation(.easeOut(duration: 2)) {
                appearBackground = true
            }
        }
        .onDisappear {
            withAnimation(.spring()) {
                appear = false
            }
            withAnimation(.easeOut(duration: 1)) {
                appearBackground = true
            }
        }
        
    }
    
    func dismissModal() {
        withAnimation {
            appear = false
            appearBackground = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            manager.fullPage = .none
        }
  
    }
}

// MARK: -   PreferenceKey+.swift

struct CirclePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ChangeKeyCenterView()
}




