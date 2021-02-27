import SwiftUI

struct MainMenuView: View {
    @ObservedObject var viewModel: MainMenuViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 32) {
                NavigationLink(destination: LazyView {
                    LevelSelectView(viewModel: viewModel.levelSelectViewModel)
                }) {
                    Text("Play")
                        .font(.title)
                        .frame(width: geometry.size.width * 0.4, height: 60)
                        .foregroundColor(Color(.systemBackground))
                        .background(Color.accentColor)
                        .cornerRadius(6)
                }
                NavigationLink(destination: LazyView {
                    LevelEditorView(viewModel: viewModel.levelEditorViewModel)
                }) {
                    Text("Level Editor")
                        .font(.title)
                        .frame(width: geometry.size.width * 0.4, height: 60)
                        .foregroundColor(Color(.systemBackground))
                        .background(Color.accentColor)
                        .cornerRadius(6)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        .navigationTitle("Main Menu")
        .navigationBarHidden(true)
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(viewModel: MainMenuViewModel(database: .empty()))
    }
}
