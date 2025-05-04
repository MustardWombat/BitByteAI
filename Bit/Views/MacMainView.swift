import SwiftUI

struct MacMainView: View {
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var shopModel: ShopModel
    @EnvironmentObject var taskModel: TaskModel
    @EnvironmentObject var currencyModel: CurrencyModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Home Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Home")
                        .font(.largeTitle)
                        .bold()
                    HomeView(currentView: .constant("Home"))
                        .frame(height: 400)
                }
                
                
                .frame(minWidth: 1200, minHeight: 800) // Ensure the window is large enough
            }
        }
    }
    
    struct MacMainView_Previews: PreviewProvider {
        static var previews: some View {
            MacMainView()
                .environmentObject(CategoriesViewModel())
                .environmentObject(XPModel())
                .environmentObject(ShopModel())
                .environmentObject(TaskModel())
                .environmentObject(CurrencyModel())
        }
    }
}
