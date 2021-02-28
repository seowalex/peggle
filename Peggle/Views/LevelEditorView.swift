// swiftlint:disable file_length

import SwiftUI

struct LevelEditorView: View {
    @EnvironmentObject var settings: GameSettings
    @StateObject var viewModel: LevelEditorViewModel

    @GestureState private var dragState: LevelEditorViewModel.DragState?

    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var levelEditorListIsPresented = false

    var body: some View {
        VStack(spacing: 0) {
            MainView()
            ToolbarView()
        }
        .navigationTitle("Level Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Text("Powerup:")
                    Picker(settings.power.rawValue, selection: $settings.power) {
                        ForEach(PowerComponent.Power.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
        .background(
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(.keyboard),
            alignment: .leading
        )
        .sheet(isPresented: $levelEditorListIsPresented) {
            LevelEditorListView(
                viewModel: viewModel.levelEditorListViewModel,
                fetchLevel: viewModel.fetchLevel
            )
            .accentColor(.init(red: 1, green: 0.75, blue: 0))
        }
        .alert(isPresented: $alertIsPresented) {
            Alert(title: Text(alertTitle), message: Text(alertMessage))
        }
    }

    private func MainView() -> some View {
        GeometryReader { geometry in
            ZStack {
                BoardView()
                    .frame(width: min(geometry.size.width, geometry.size.height),
                           height: min(geometry.size.width, geometry.size.height))
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
    }

    private func BoardView() -> some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

            ZStack {
                ForEach(viewModel.level.elements, id: \.self) { element in
                    ElementView(element: element, frame: frame)
                }

                if let element = viewModel.selectedElement {
                    ElementSelectView(element: element, frame: frame)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragState) { value, state, _ in
                        state = viewModel.onDrag(position: value.location.applying(normalize))
                    }
                    .onEnded { value in
                        viewModel.onDragEnd(position: value.location.applying(normalize))
                    }
            )
        }
    }

    private func ElementView(element: Element, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)

        return Image(element.imageName)
            .resizable()
            .contentShape(element is Peg ? AnyShape(Circle()) : AnyShape(Rectangle()))
            .opacity(dragState?.element === element ? 0.4 : 1)
            .rotationEffect(.radians(Double(element.rotation)))
            .frame(width: element.size.applying(denormalize).width, height: element.size.applying(denormalize).height)
            .position(element.position.applying(denormalize))
            .clipped()
            .gesture(
                ExclusiveGesture(LongPressGesture(), DragGesture(minimumDistance: 0))
                    .updating($dragState) { value, state, _ in
                        state = viewModel.onDrag(value: value, element: element, frame: frame)
                    }
                    .onEnded { value in
                        viewModel.onDragEnd(value: value, element: element, frame: frame)
                    }
            )
    }

    private func ToolbarView() -> some View {
        VStack(spacing: 20) {
            PaletteView()
            ActionBarView()
        }
        .padding()
        .background(Color(UIColor.systemBackground).shadow(radius: 10))
        .disabled(dragState != nil)
    }

    private func PaletteView() -> some View {
        HStack(spacing: 16) {
            PaletteButtonView(selection: .addPeg(.blue), imageName: "peg-blue")
            PaletteButtonView(selection: .addPeg(.orange), imageName: "peg-orange")
            PaletteButtonView(selection: .addBlock, imageName: "block")
            Spacer()
            PaletteButtonView(selection: .delete, imageName: "delete")
        }
    }

    private func ActionBarView() -> some View {
        HStack(spacing: 16) {
            Button(action: {
                levelEditorListIsPresented = true
            }) {
                Text("Load")
            }
            Button(action: save) {
                Text("Save")
            }
            Button(action: viewModel.reset) {
                Text("Reset")
            }
            TextField("Level Name", text: $viewModel.level.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            NavigationLink(destination: LazyView {
                LevelPlayerView(viewModel: LevelPlayerViewModel(level: viewModel.level, power: settings.power))
            }) {
                Text("Start")
            }
        }
    }

    private func PaletteButtonView(selection: LevelEditorViewModel.PaletteSelection, imageName: String) -> some View {
        var count = ""

        switch selection {
        case .addPeg(.blue):
            count = String(viewModel.level.elements.compactMap { $0 as? Peg }.filter { $0.color == .blue }.count)
        case .addPeg(.orange):
            count = String(viewModel.level.elements.compactMap { $0 as? Peg }.filter { $0.color == .orange }.count)
        case .addBlock:
            count = String(viewModel.level.elements.compactMap { $0 as? Block }.count)
        default:
            break
        }

        return Button(action: {
            if case .delete = selection {
                viewModel.selectedElement = nil
            }

            viewModel.paletteSelection = selection
        }) {
            ZStack {
                Image(imageName)
                    .resizable()
                    .frame(width: 100, height: 100)

                Text(count)
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1)
            }
            .opacity(viewModel.paletteSelection == selection ? 1 : 0.4)
        }
    }

    private func save() {
        do {
            try viewModel.saveLevel()

            alertTitle = "Level saved"
            alertMessage = ""
            alertIsPresented = true
        } catch {
            if let title = (error as? LocalizedError)?.errorDescription,
               let message = (error as? LocalizedError)?.recoverySuggestion {
                alertTitle = title
                alertMessage = message
            } else {
                alertTitle = "Database error"
                alertMessage = "\(error)"
            }

            alertIsPresented = true
        }
    }
}

extension LevelEditorView {
    private func ElementSelectView(element: Element, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)

        let position = dragState?.position ?? element.position
        let size = dragState?.size ?? element.size
        let rotation = dragState?.rotation ?? element.rotation
        let isValid = dragState?.isValid ?? true

        return ZStack {
            Rectangle()
                .rotation(.radians(Double(rotation)))
                .stroke(Color.white)
                .frame(width: size.applying(denormalize).width, height: size.applying(denormalize).height)
                .position(position.applying(denormalize))
                .allowsHitTesting(false)

            if element.isOscillating == true {
                OscillatePathView(element: element, frame: frame)
            }

            Image(element.imageName)
                .resizable()
                .rotationEffect(.radians(Double(rotation)))
                .frame(width: size.applying(denormalize).width, height: size.applying(denormalize).height)
                .position(position.applying(denormalize))
                .colorMultiply(isValid ? .white : .gray)
                .allowsHitTesting(false)

            ResizeHandleView(element: element, frame: frame)
            RotateHandleView(element: element, frame: frame)

            if element.isOscillating == true {
                OscillateHandleView(element: element, frame: frame)
                FrequencyHandleView(element: element, frame: frame)
            }
        }
        .clipped()
    }

    private func ResizeHandleView(element: Element, frame: CGRect) -> some View {
        ZStack {
            ResizeHandleView(element: element, frame: frame, direction: .top)
            ResizeHandleView(element: element, frame: frame, direction: .bottom)
            ResizeHandleView(element: element, frame: frame, direction: .left)
            ResizeHandleView(element: element, frame: frame, direction: .right)
        }
    }

    private func ResizeHandleView(element: Element, frame: CGRect,
                                  direction: LevelEditorViewModel.Direction) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)
        let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

        let elementPosition = dragState?.position ?? element.position
        let elementSize = dragState?.size ?? element.size
        let elementRotation = dragState?.rotation ?? element.rotation

        var difference = CGVector.zero
        let size = CGSize(width: min(elementSize.width, Element.minimumSize.width) / 2,
                          height: min(elementSize.height, Element.minimumSize.height) / 2)
        let touchSize = CGSize(width: min(elementSize.width / 2, Element.minimumSize.width),
                               height: min(elementSize.height / 2, Element.minimumSize.height))

        switch direction {
        case .top:
            difference = CGVector(dx: 0, dy: -elementSize.height / 2)
        case .bottom:
            difference = CGVector(dx: 0, dy: elementSize.height / 2)
        case .left:
            difference = CGVector(dx: -elementSize.width / 2, dy: 0)
        case .right:
            difference = CGVector(dx: elementSize.width / 2, dy: 0)
        }

        let position = (elementPosition + difference).rotate(around: elementPosition, by: elementRotation)

        return Rectangle()
            .rotation(.radians(Double(elementRotation)))
            .foregroundColor(Color.clear)
            .contentShape(Rectangle())
            .background(
                Rectangle()
                    .rotation(.radians(Double(elementRotation)))
                    .foregroundColor(.white)
                    .frame(width: size.applying(denormalize).width, height: size.applying(denormalize).height)
            )
            .frame(width: touchSize.applying(denormalize).width, height: touchSize.applying(denormalize).height)
            .position(position.applying(denormalize))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragState) { value, state, _ in
                        state = viewModel.onResize(position: value.location.applying(normalize),
                                                   element: element, direction: direction)
                    }
                    .onEnded { value in
                        viewModel.onResizeEnd(position: value.location.applying(normalize),
                                              element: element, direction: direction)
                    }
            )
    }

    private func RotateHandleView(element: Element, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)
        let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

        let elementPosition = dragState?.position ?? element.position
        let elementSize = dragState?.size ?? element.size
        let elementRotation = dragState?.rotation ?? element.rotation

        let size = CGSize(width: min(elementSize.width, Element.minimumSize.width) / 2,
                          height: min(elementSize.height, Element.minimumSize.height) / 2)
        let position = (elementPosition - CGVector(dx: 0, dy: elementSize.height / 2 + Element.minimumSize.height))
            .rotate(around: elementPosition, by: elementRotation)

        return Circle()
            .foregroundColor(Color.clear)
            .contentShape(Circle())
            .background(
                ZStack {
                    Rectangle()
                        .position(x: 0.5, y: Element.minimumSize.applying(denormalize).height)
                        .rotationEffect(.radians(Double(elementRotation)))
                        .frame(width: 1, height: Element.minimumSize.applying(denormalize).height)
                        .foregroundColor(.white)
                        .allowsHitTesting(false)
                    Circle()
                        .foregroundColor(.white)
                        .frame(width: size.applying(denormalize).width, height: size.applying(denormalize).height)
                }
            )
            .frame(width: Element.minimumSize.applying(denormalize).width,
                   height: Element.minimumSize.applying(denormalize).height)
            .position(position.applying(denormalize))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragState) { value, state, _ in
                        state = viewModel.onRotate(position: value.location.applying(normalize), element: element)
                    }
                    .onEnded { value in
                        viewModel.onRotateEnd(position: value.location.applying(normalize), element: element)
                    }
            )
    }

    private func OscillateHandleView(element: Element, frame: CGRect) -> some View {
        ZStack {
            OscillateHandleView(element: element, frame: frame, direction: .left)
            OscillateHandleView(element: element, frame: frame, direction: .right)
        }
    }

    private func OscillateHandleView(element: Element, frame: CGRect,
                                     direction: LevelEditorViewModel.Direction) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)
        let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

        let elementPosition = dragState?.position ?? element.position
        let elementSize = dragState?.size ?? element.size
        let elementRotation = dragState?.rotation ?? element.rotation

        var coefficient = CGFloat.zero
        var color = Color.clear

        if case .left = direction {
            coefficient = element.minCoefficient
            color = .green
        } else if case .right = direction {
            coefficient = element.maxCoefficient
            color = .red
        }

        let position = (elementPosition + CGVector(dx: coefficient * elementSize.width, dy: 0))
            .rotate(around: elementPosition, by: elementRotation)
        let size = CGSize(width: min(elementSize.width, Element.minimumSize.width) / 2,
                          height: min(elementSize.height, Element.minimumSize.height) / 2)
        let touchSize = CGSize(width: min(elementSize.width / 2, Element.minimumSize.width),
                               height: min(elementSize.height / 2, Element.minimumSize.height))

        return Rectangle()
            .rotation(.radians(Double(elementRotation)))
            .foregroundColor(Color.clear)
            .contentShape(Rectangle())
            .background(
                Rectangle()
                    .rotation(.radians(Double(elementRotation + CGFloat.pi / 4)))
                    .foregroundColor(color)
                    .frame(width: size.applying(denormalize).width, height: size.applying(denormalize).height)
            )
            .frame(width: touchSize.applying(denormalize).width, height: touchSize.applying(denormalize).height)
            .position(position.applying(denormalize))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if case .left = direction {
                            viewModel.onOscillateMin(position: value.location.applying(normalize), element: element)
                        } else if case .right = direction {
                            viewModel.onOscillateMax(position: value.location.applying(normalize), element: element)
                        }
                    }
            )
    }

    private func OscillatePathView(element: Element, frame: CGRect) -> some View {
        ZStack {
            OscillatePathView(element: element, frame: frame, direction: .left)
            OscillatePathView(element: element, frame: frame, direction: .right)
        }
    }

    private func OscillatePathView(element: Element, frame: CGRect,
                                   direction: LevelEditorViewModel.Direction) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)

        let elementPosition = dragState?.position ?? element.position
        let elementSize = dragState?.size ?? element.size
        let elementRotation = dragState?.rotation ?? element.rotation

        var coefficient = CGFloat.zero
        var color = Color.clear

        if case .left = direction {
            coefficient = element.minCoefficient
            color = .green
        } else if case .right = direction {
            coefficient = element.maxCoefficient
            color = .red
        }

        let position = (elementPosition + CGVector(dx: coefficient * elementSize.width / 2, dy: 0))
            .rotate(around: elementPosition, by: elementRotation)

        return Rectangle()
            .rotation(.radians(Double(elementRotation)))
            .frame(width: abs(coefficient) * elementSize.applying(denormalize).width, height: 4)
            .position(position.applying(denormalize))
            .foregroundColor(color)
            .allowsHitTesting(false)
    }

    private func FrequencyHandleView(element: Element, frame: CGRect) -> some View {
        let denormalize = CGAffineTransform(scaleX: frame.maxX, y: frame.maxY)
        let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)

        let elementPosition = dragState?.position ?? element.position
        let elementSize = dragState?.size ?? element.size
        let elementRotation = dragState?.rotation ?? element.rotation

        let coefficient = 0.5 - element.frequency
        let position = (elementPosition + CGVector(dx: 0, dy: coefficient * elementSize.height))
            .rotate(around: elementPosition, by: elementRotation)
        let size = CGSize(width: min(elementSize.width, Element.minimumSize.width) / 2,
                          height: min(elementSize.height, Element.minimumSize.height) / 2)
        let touchSize = CGSize(width: min(elementSize.width / 2, Element.minimumSize.width),
                               height: min(elementSize.height / 2, Element.minimumSize.height))

        return Rectangle()
            .rotation(.radians(Double(elementRotation)))
            .foregroundColor(Color.clear)
            .contentShape(Rectangle())
            .background(
                Rectangle()
                    .rotation(.radians(Double(elementRotation + CGFloat.pi / 4)))
                    .foregroundColor(.orange)
                    .frame(width: size.applying(denormalize).width, height: size.applying(denormalize).height)
            )
            .frame(width: touchSize.applying(denormalize).width, height: touchSize.applying(denormalize).height)
            .position(position.applying(denormalize))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        viewModel.onFrequency(position: value.location.applying(normalize), element: element)
                    }
            )
    }
}

struct LevelEditorView_Previews: PreviewProvider {
    static var previews: some View {
        LevelEditorView(viewModel: LevelEditorViewModel(database: .empty()))
    }
}
