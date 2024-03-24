import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    let stepCountLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        requestAuthorization()
    }
    
    func setupUI() {
        stepCountLabel.frame = CGRect(x: 0, y: 100, width: view.frame.width, height: 50)
        stepCountLabel.textAlignment = .center
        stepCountLabel.text = "Шагов сегодня: -"
        view.addSubview(stepCountLabel)
    }
    
    func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        healthStore.requestAuthorization(toShare: [], read: [stepType]) { (success, error) in
            if success {
                self.getTodaysStepCount()
            } else {
                print("Ошибка при запросе авторизации для HealthKit: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func getTodaysStepCount() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("Шаги не поддерживаются на этом устройстве.")
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, result, error) in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    print("Не удалось получить данные о шагах: \(error?.localizedDescription ?? "")")
                    return
                }
                let stepCount = sum.doubleValue(for: HKUnit.count())
                self.stepCountLabel.text = "Шагов сегодня: \(Int(stepCount))"
            }
        }
        healthStore.execute(query)
    }
}

class FirstViewController: UIViewController {
    
    @IBOutlet weak var messageTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToSecond" {
            if let destinationVC = segue.destination as? SecondViewController {
                destinationVC.receivedMessage = messageTextField.text
            }
        }
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        performSegue(withIdentifier: "segueToSecond", sender: self)
    }
}

class SecondViewController: UIViewController {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    var receivedMessage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let message = receivedMessage {
            messageLabel.text = message
        }
    }
    
    @IBAction func goBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let firstVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FirstViewController")
        firstVC.tabBarItem = UITabBarItem(title: "First", image: UIImage(named: "first_icon"), tag: 0)
        
        let secondVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SecondViewController")
        secondVC.tabBarItem = UITabBarItem(title: "Second", image: UIImage(named: "second_icon"), tag: 1)
        
        viewControllers = [firstVC, secondVC]
    }
}
