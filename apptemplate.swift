//
//  dripApp.swift
//  drip
//
//  Created by Sid Ajay on 5/9/21.
//  References: Stack Overflow, Hacking With Swift, Arduino Website, Apple Website, Swift website

import SwiftUI
import CoreLocation

//colors
let darkgreen = Color(red: 1/255, green: 100/255, blue: 2/255)
let bgcolor = Color(red: 164/255, green: 217/255, blue: 128/255)
let dbcolor = Color(red:0,green:0,blue:255)

//status
public var status: Int = -1
public var raining: Bool = false
public var auth = "0"

//scheduled watering
public var startHours: Int = 0
public var startMinutes: Int = 0

public var endHours: Int = 0
public var endMinutes: Int = 0

public var interval: Double = 0

//HTTP GET request response110
public struct Response: Codable {
    var status: Int
}

//Response from weather API
public struct weatherResponse: Codable {
    var coords: [String:Int]
    var weather: [Dictionary<String,String>]
    var base: String
    var main: [String:Int]
    var visibility: Int
    var wind: [String:Int]
    var rain: [String:Int]?
    var clouds: [String:Int]
    var dt: Int
    var sys: Dictionary<String,String>
    var timezone: Int
    var id: Int
    var name: String
    var cod: Int
}

//HTTP POST request payload
public struct Status: Codable {
    var type: String
    var val: Int
    var auth: Int
}

/*public struct routine: Codable {
    var name: String
    var startHours: Int
    var startMinutes: Int
    var endHours: Int
    var endMinutes: Int
    var interval: Double
}
*/
// Preset dictionary
public struct plantPreset: Codable {
    var waterNeeded: Double // Liters
    var timeSpan: Double // days
    var timeOfDay: String
    var notes: String // Notes and distance from other plants
    var startTime: [Int]
    var endTime: [Int]
}

//Presets based on specific plant data
public var presetDict: [String:plantPreset] = [
    "Tomato":plantPreset(waterNeeded: 0.64, timeSpan: 1, timeOfDay: "Early morning", notes: "Container plants need slightly more water. Recommended distance from other plants: 2-3 feet",startTime: [6,0,0],endTime: [6,2,0]),
    "Cucumber":plantPreset(waterNeeded: 0.32, timeSpan: 1, timeOfDay: "morning or early afternoon", notes: "Can be on mounds. Recommended distance from other plants: 2-3 feet", startTime: [11,0,0],endTime: [11,1,0]),
    "Strawberry":plantPreset(waterNeeded: 0.32, timeSpan: 1, timeOfDay: "morning", notes: "Can last over the winter. Recommended distance from other plants: 1.5 feet", startTime: [9,0,0],endTime: [9,1,0]),
    "Lettuce":plantPreset(waterNeeded: 0.32, timeSpan: 4, timeOfDay: "morning", notes: "Needs a lot of attention. Recommended distance from other plants: 12-15 inches", startTime: [9,0,0],endTime: [9,1,0]),
    "Basil":plantPreset(waterNeeded: 0.32, timeSpan: 4, timeOfDay: "morning", notes: "It is best to plant it with tomatoes. Recommended distance from other plants: 10-12 inches", startTime: [9,0,0],endTime: [9,1,0]),
    "Parsley":plantPreset(waterNeeded: 0.48, timeSpan: 1, timeOfDay: "morning", notes: "Recommended distance from other plants: 6-8 inches", startTime: [9,0,0],endTime: [9,2,0]),
    "Oregano":plantPreset(waterNeeded: 0.64, timeSpan: 7, timeOfDay: "morning", notes: "Does not need much watering. Recommended distance from other plants: 8-10 inches", startTime: [9,0,0],endTime: [9,2,0]),
    "Bell Pepper":plantPreset(waterNeeded: 0.48, timeSpan: 1, timeOfDay: "morning", notes: "Needs slightly acidic soil (6.0 - 7.0 pH). Recommended distance from other plants: 18-24 inches", startTime: [9,0,0],endTime: [9,2,0])
]

//public var Routines: [routine] = []

//POST request
func StartStop(type: String, val: Int){
    let payload: [String:String] = ["type":type,"val":"\(val)","auth":auth]
    print(payload)
    let payloadEncoded = try! JSONSerialization.data(withJSONObject: payload)
    guard let url = URL(string:"http://192.168.1.23:5000/" ) else {return}
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = payloadEncoded
    print("e:\(payloadEncoded)")
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            if let decodedData = try? JSONDecoder().decode(Response.self, from: data) {
                print("d:\(decodedData)")
                
            }
        }
        

    }.resume()
    
    }

//GET request
func loadStatus(){
    guard let url = URL(string:"http://192.168.1.23:5000/" ) else {
        print("SCREE")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    print(request)
    URLSession.shared.dataTask(with: request) { data, response, error in
        print("e")
        if let data = data {
            if let decodedResponse = try? JSONDecoder().decode(Response.self, from: data) {
                DispatchQueue.main.async {
                    print(decodedResponse.status)
                    status = decodedResponse.status
                        }
                
                return
            }
        }

    }.resume()
    }

//GET request to weather api
func loadWeather(/*latitude: Int,longitude: Int*/){
    let lat = 38//CLLocationManager().location?.coordinate.latitude
    let lon = 128//CLLocationManager().location?.coordinate.longitude
    let key = "0061ff84eff2d81e5a35275acb8a472b"
    print(lat)
    print(lon)
    print(raining)
    guard let url = URL(string: "http://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(key)") else {return}
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    print(request)
    URLSession.shared.dataTask(with: request) { data, response, error in
        print("e")
        if let data = data{
            DispatchQueue.main.async{print("encoded")}
            if let decodedResponse = try? JSONDecoder().decode(weatherResponse.self, from: data) {
                print("decoded")
                DispatchQueue.main.async{
                    print(decodedResponse.weather)
                    if decodedResponse.weather[0]["main"] == "Rain"
                    {
                        raining = true
                    }
                    else {raining = false}
                }
            }
        }
        print("sadj")
    }
}

//ManualControl Tab
struct ManualControl: View {
    @State var image = "offbutton"
    var body: some View {
        ZStack {
            bgcolor.ignoresSafeArea()
            //Image("g r a ss")
            // . resizable().aspectRatio(1.5,contentMode: .fill)
            
            VStack(){
                Spacer()
                    //On Off Button
                    Button(action:{
                        print(status)
                        StartStop(type: "0",val: status * -1)
                        
                        //Delay
                        let seconds = 0.2
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                            loadStatus()
                            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                                if status == 1 {
                                    image = "onbutton"
                                }
                                else {
                                    image = "offbutton"
                                }
                                print(status)
                                print(image)
                            }
                        }
                        
                    }){
                        //Visual for button
                        Image(image).resizable()
                    }.frame(width:100,height:100,alignment: .center)
                    .padding()

                Spacer()
            }
            .frame(width: 300.0, height: 500.0,alignment: .top)
            }
        }
}

//Settings Tab
struct Settings: View {
    @State var skip_during_rain = false
    @State var send_alert = false
    @State var skip_duration = 1.0
    @State var authTemp = ""
    var body: some View {
        ZStack{
            
            bgcolor.ignoresSafeArea()
            VStack{
                HStack{
                    //First Toggle
                    Image(systemName: "cloud.rain")
                    Toggle("Autoskip Watering When Raining?", isOn: $skip_during_rain)
                }
                //Drop down button if toggle above is true
                if skip_during_rain{
                VStack{
                    HStack{
                    //Second Toggle
                    Image(systemName: "cloud.heavyrain")
                    Text("How Many Days Without Water After Rain?")
                    }
                    Slider(value: $skip_duration,
                           in: 0...31, step: 1.0)
                    Text(String(format: "%g",skip_duration))
                }
                }

                HStack{
                    //Third Toggle
                    Image(systemName: "cloud.drizzle")
                    Toggle("Send Alert If Raining?", isOn: $send_alert)
                }
                Spacer()
                Button(action: {
                    loadWeather()
                }){
                    //Rain Image
                    Image(systemName:"cloud.rain").resizable().scaledToFit().foregroundColor(.green)
                }.padding()
                Spacer()
                HStack{
                    Text("Auth Code:")
                    TextField("Type Here",text:$authTemp)
                    Button(action:{auth = authTemp}) {Text("Submit")}
                }
                
            }.padding()
            

        }
    }
}

//Presets Tab
struct Presets: View {
    @State private var preset = 0
    @Binding var start: [Int]
    @Binding var end: [Int]
    @Binding var dayInterval: Double
    @Binding var tab: Int
    var body: some View {
        ZStack {
            bgcolor.ignoresSafeArea()
            VStack {
                Text("Select a preset:")
                Picker(selection: $preset, label: Text("Presets...")) {
                    let options = Array(presetDict.keys)
                    ForEach(0..<options.count) {
                        Text("\(options[$0])")
                    }
                }
                Spacer()
                ScrollView {
                    VStack {
                        let selectedPlant = presetDict[Array(presetDict.keys)[preset]]!
                        Text("Water Needed: \(String(format:"%g", selectedPlant.waterNeeded)) L")
                        if selectedPlant.timeSpan != 1 {
                        Text("Water every \(String(format:"%g", selectedPlant.timeSpan)) days")
                        } else {
                        Text("Water every day")
                        }
                        Text("Water in the \(selectedPlant.timeOfDay)")
                        Text(selectedPlant.notes)
                            .padding()
                    }
                }
                Spacer()
                Button(action:{
                    let selectedPlant = presetDict[Array(presetDict.keys)[preset]]!
                    start = selectedPlant.startTime
                    end = selectedPlant.endTime
                    dayInterval = selectedPlant.timeSpan
                    tab = 3
                    //CustomSetups(start: $start, end: $end, dayInterval: $dayInterval)
                    
                }) {
                    Text("Set preset")

                } .font(.system(size:20))
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 1)


                )

                Spacer()
            }
        }
    }
}

//Custom Setup Tab
struct CustomSetups: View {
    @State var page: Int = 0
    @Binding var start: [Int]
    @Binding var end: [Int]
    @Binding var dayInterval: Double
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                bgcolor.ignoresSafeArea()
                NavigationView{
                    ZStack {
                        bgcolor.ignoresSafeArea()
                            ScrollView(.vertical){
                                
                                VStack(){
                                    Spacer()
                                    HStack{
                                        VStack{
                                            Text("Start Time").font(.system(size:15,weight:.heavy))
                                    if start[2] == 1{Text("\(start[0]-12):\(String(format:"%02d",start[1])) pm")}
                                    else{Text("\(start[0]):\(String(format:"%02d",start[1])) am")}
                                        }.padding()
                                        VStack{
                                            Text("End Time").font(.system(size:15,weight:.heavy))
                                    if end[2] == 1{Text("\(end[0]-12):\(String(format:"%02d",end[1])) pm")}
                                    else{Text("\(end[0]):\(String(format:"%02d",end[1])) am")}
                                        }.padding()
                                    }
                                    Spacer()
                                    Text("Days Between Watering: \(String(format:"%g",dayInterval))")
                                    Spacer()
                                    Image(systemName: "leaf.fill").resizable().scaledToFit().padding(75).foregroundColor(.green)
                                    /*if numroutines == 0 {
                                        Text("No custom setups made. Tap the plus sign to make one!")
                                    }
                                    if numroutines > 0{
                                        ForEach(0..<numroutines,id:\.self){
                                        let index = $0
                                            VStack {
                                                HStack{
                                                Text("\(Routines[index].name)").padding()
                                                    .font(.system(size:20,weight: .heavy))
                                                    
                                                Spacer()
                                                VStack{
                                                    Spacer()
                                                    if Routines[index].startHours > 12{
                                                        HStack {
                                                            Text("\(Routines[index].startHours - 12):\(String(format:"%02d",Routines[index].startMinutes)) ")
                                                                .font(.system(size:30,weight: .heavy))
                                                            Text("pm").font(.system(size:30,weight: .heavy))
                                                        }.padding()
                                                    }
                                                    else {
                                                        HStack {
                                                            Text("\(Routines[index].startHours ):\(String(format:"%02d",Routines[index].startMinutes))")
                                                                .font(.system(size:30,weight: .heavy))
                                                            Text("am").font(.system(size:30,weight: .heavy))
                                                        }.padding()
                                                    }
                                                    Spacer()
                                                    
                                                    if Routines[index].endHours > 12{
                                                    
                                                        HStack {
                                                            Text("\(Routines[index].endHours-12):\(String(format:"%02d",Routines[index].endMinutes))")
                                                                .font(.system(size:30,weight: .heavy))
                                                            Text("pm").font(.system(size:30,weight: .heavy))
                                                        }.padding()
                                                    }
                                                    else {
                                                        HStack {
                                                            Text("\(Routines[index].endHours):\(String(format:"%02d",Routines[index].endMinutes))")
                                                                .font(.system(size:30,weight: .heavy))
                                                            Text("am").font(.system(size:30,weight: .heavy))
                                                        }.padding()
                                                    }
                                                    
                                                }
                                                }
                                                Text("Days Between Watering: \(String(format:"%g", Routines[index].interval)) Days")
                                                    .padding()
                                            }.border(Color.black)
                                    }
                                    }*/
                                }
                            }
                            .navigationBarTitle("Custom Setups")
                            .navigationBarItems(trailing:
                                Button(action: {page = 1}){
                                    Text("Edit").underline()
                                        .padding()
                                } )
                            
                            HStack {
                                Spacer()
                                
                            }
                            
                                Spacer()
                        
                    }
                }
                if page == 1{
                    setCustom(startTime: $start, endTime: $end, interval: $dayInterval,page: $page) .background(RoundedRectangle(cornerRadius: 20).fill(bgcolor)).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 1))
                        .padding(.top)
                        .animation(.linear )
                        .transition(.offset(x: 0, y: geometry.size.height*2.5))
                }
                
            }
        }
    }
}

struct setCustom: View {
    @Binding var startTime: [Int]
    @Binding var endTime: [Int]
    @Binding var interval: Double
    @State var startPm = 0
    @State var endPm = 0
    @State var name = "Unnamed Routine"
    var ampm: [String] = ["am","pm"]
    @Binding var page: Int
    
    
    var body: some View {
        NavigationView {
            ZStack{
                bgcolor.ignoresSafeArea()
                ScrollView {
                    VStack {
                        HStack{
                            Spacer()
                            Text("Routine Name: ")
                            TextField("Type Here",text:$name)
                            Spacer()
                        }
                        VStack{
                            Text("Days Between Watering?")
                            Slider(value: $interval, in:0...31, step:1.0)
                            Text(String(format: "%g",interval))
                        }
                        HStack{
                            Text("Start Time")
                            Picker("",selection:$startTime[0]){
                                ForEach(1..<13){
                                    Text("\($0)")
                                }
                            }.frame(width:50).clipped()
                            Picker("",selection:$startTime[1]){
                                ForEach(00..<60){
                                    Text(String(format: "%02d", $0))
                                }
                            }.frame(width:50).clipped()
                            Picker("",selection:$startTime[2]){
                                ForEach(0..<2){
                                Text(ampm[$0])
                                }
                            }.frame(width:50).clipped()
                        }
                        HStack{
                            Text("End Time")
                            Picker("",selection:$endTime[0]){
                                ForEach(1..<13){
                                    Text("\($0)")
                                }
                            }.frame(width:50).clipped()
                            Picker("",selection:$endTime[1]){
                                ForEach(00..<60){
                                    Text(String(format: "%02d", $0))
                                }
                            }.frame(width:50).clipped()
                            Picker("",selection:$endTime[2]){
                                ForEach(0..<2){
                                Text(ampm[$0])
                                }
                            }.frame(width:50).clipped()
                        }
                    }
                }
                
                .navigationBarItems(trailing:
                    Button(action:{
                        page = 0
                        if startTime[2] == 1{startTime[0] = startTime[0] + 13}
                        else {startTime[0] = startTime[0]+1}
                        
                        if endTime[2] == 1{endTime[0] = endTime[0]+13}
                        else{endTime[0] = endTime[0]+1}
                        
                    }) {
                        ZStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 15)
                                .fill(bgcolor)
                                .frame(width: 320, height: 40)
                                .offset(x: 4)
                            Rectangle()
                                .fill(bgcolor)
                                .frame(width:320, height: 10)
                                .offset(x: 4, y: 16)
                        
                            Text("Save").underline()
                            .frame(width: 300, height: 40, alignment: .trailing)
                            
                    }
                    }
            )
            }
            
            }
        }
}


//Main Menu/View
struct Menu: View {
    @State var selection = 2
    @State var start = [startHours,startMinutes,0]
    @State var end = [startHours,startMinutes,0]
    @State var dayInterval: Double = interval
        
    var body: some View {
        //Tab Bar at bottom
        TabView(selection: $selection){
        Settings()
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
            .tag(1)
        ManualControl()
                .tabItem {
                Image(systemName: "power")
                Text("Manual")
                    
                }.tag(2)
            CustomSetups(start: $start, end: $end, dayInterval: $dayInterval)
            .tabItem {
                Image(systemName: "square.grid.2x2")
                Text("Custom")
            
                
            }
            .tag(3)
            Presets(start: $start, end: $end, dayInterval: $dayInterval, tab: $selection)
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Plant Presets")
            }
            .tag(4)
            
        }

    }
}

struct dripPreview: PreviewProvider {
    static var previews: some View {
        Menu()
    }
}

@main
struct dripApp: App {
    var body: some Scene {
        WindowGroup {
            Menu()
        }
    }
}
