import Foundation
import UIKit

public class Person: NSObject {
    @objc public dynamic var firstName: String
    @objc public dynamic var middleInitial: String?
    @objc public dynamic var lastName: String

    public init(firstName: String, middleInitial: String?, lastName: String) {
        self.firstName = firstName
        self.middleInitial = middleInitial
        self.lastName = lastName
        super.init()
    }

    public func abbreviateName() {
        firstName.removeLast()
    }
}

public class PersonViewModel: NSObject {
    @objc public dynamic var person: Person?

    // observable fields
    @objc public dynamic var personNameText: String? = "initial" //for testing
    @objc public dynamic var abbreviateNameButtonEnabled = true

    public init(person: Person?) {
        self.person = person
        super.init()
        bindPerson()
    }

    // note: unclear if we need this for newer versions of iOS
    deinit {
        self.personObserver = nil
        self.personObservers.removeAll()
    }

    @objc func didPressAbbreviateName() {
        guard abbreviateNameButtonEnabled else { return }

        abbreviateNameButtonEnabled = false
        person?.abbreviateName()
        abbreviateNameButtonEnabled = true
    }

    // MARK: observe changes to models

    private var personObserver: NSKeyValueObservation?
    private var personObservers = [NSKeyValueObservation]()
    private func bindPerson() {
        self.personObserver = observe(\.person, options: [.initial, .new], changeHandler: {[unowned self] (object, change) in
            self.personObservers.removeAll()

            if let newPerson = change.newValue as? Person {
                self.personObservers = [\Person.firstName, \Person.lastName].map {
                    newPerson.observe($0, options: [.initial, .new], changeHandler: {[unowned self] object, change in
                        self.updatePersonName()
                    })
                } + [\Person.middleInitial].map {
                    newPerson.observe($0, options: [.initial, .new], changeHandler: {[unowned self] object, change in
                        self.updatePersonName()
                    })
                }
            }
        })
    }

    private func updatePersonName() {
        if let person = person {
            self.personNameText = "\(person.firstName) \(person.lastName)"
        } else {
            self.personNameText = "no person"
        }
    }
}

class PersonView {
    var personNameLabel: UILabel
    var abbreviateNameButton: UIButton
    var backButton: UIButton
    private var viewModel: PersonViewModel

    init(person: Person?) {
        viewModel = PersonViewModel(person: person)
        personNameLabel = UILabel(frame: CGRect.zero)
        abbreviateNameButton = UIButton(frame: CGRect.zero)
        backButton = UIButton(frame: CGRect.zero)
        backButton.addTarget(self, action: #selector(PersonView.viewWillDisappear), for: .touchUpInside)
        viewWillAppear(animated: true)
    }

    func changePerson(person: Person?) {
        viewModel.person = person
    }

    // mock
    func viewWillAppear(animated: Bool) {
        bindViewModel()
    }

    // mock
    @objc func viewWillDisappear() {
        unbindViewModel()
    }

    private var observers = [NSKeyValueObservation]()
    func bindViewModel() {
        abbreviateNameButton.addTarget(viewModel, action: #selector(PersonViewModel.didPressAbbreviateName), for: .touchUpInside)
        observers.append(
            viewModel.observe(\PersonViewModel.personNameText, options: [.initial, .new], changeHandler: {[unowned self] (object, change) in
                self.personNameLabel.text = change.newValue as? String
            })
        )
    }

    func unbindViewModel() {
        abbreviateNameButton.removeTarget(viewModel, action: #selector(PersonViewModel.didPressAbbreviateName), for: .touchUpInside)
    }
}

func main() {
    let me = Person(firstName: "Peter", middleInitial: nil, lastName: "C")
    let daisy = Person(firstName: "Daisy", middleInitial: nil, lastName: "J")

    let view = PersonView(person: nil)
    print("button enabled? \(view.abbreviateNameButton.isEnabled)")
    print(view.personNameLabel.text ?? "nil")
    view.changePerson(person: me)
    print("button enabled? \(view.abbreviateNameButton.isEnabled)")
    print(view.personNameLabel.text ?? "nil")
    view.abbreviateNameButton.sendActions(for: .touchUpInside)
    print(view.personNameLabel.text ?? "nil")
    view.changePerson(person: daisy)
    print(view.personNameLabel.text ?? "nil")
}

main()
