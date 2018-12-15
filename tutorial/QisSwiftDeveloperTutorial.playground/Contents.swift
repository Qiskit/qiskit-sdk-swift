
/*:
![Playground icon](QISKit-c.gif)

[https://github.com/QISKit/qiskit-sdk-swift]: https://github.com/QISKit/qiskit-sdk-swift "IBM QISKit Swift SDK"

 ## Getting Started with the QISKit Swift API
 The Official API Client to use **IBM Quantum Experience in Swift**.
 The latest version of this playground is available on [https://github.com/QISKit/qiskit-sdk-swift].
 For more information about how to use the Quantum Experience consult the Quantum Experience tutorials or check-out the examples folder.
*/

/*:
 [OpenQASM 2.0]: https://github.com/IBM/qiskit-openqasm "Open Qasm 2.0"
 ## Quantum QISKit SDK tutorial
 This tutorial aims to explain how to use the QISKit Swift SDK, but from a developer's point-of-view. We review the steps it takes to install and start to use the SDK tools.
 QISKit is a Swift software development kit (SDK) that you can use to create your quantum computing programs, based on circuits defined through the [OpenQASM 2.0] specification, compiled and then executed on several Backends (Real Quantum Processors online, Simulators online and Simulators). For the online Backends QISKit uses our Swift API connector to the IBM Quantum Experience project.
 Once you get through this, we have other tutorials that introduce you to more complex concepts directly related with quantum computing.
*/
/*:
 [superposition and engtanglement]: https://render.github.ibm.com/view/superposition_and_entanglement.ipynb "super position and entanglement"
 [entanglement revisited]: https://render.github.ibm.com/view/entanglement_revisited.ipynb "entanglement revisited"
 More examples:
 - Get a basic familiarity with the important concepts of  [superposition and engtanglement].
 - Go beyond and explore a bit more in-depth in [entanglement revisited].
*/

/*:
 [https://github.com/QISKit/qiskit-sdk-swift]: https://github.com/QISKit/qiskit-sdk-swift "qiskit swift sdk"
 ## Installation
 If you have not yet installed the Swift interface to the web API of the Quantum Experience you can install it using Carthage. Alternatively you can install it by cloning the following git repository [https://github.com/QISKit/qiskit-sdk-swift].
*/

/*:
 ## Getting Started
 Now it's time to begin doing real work with Swift and the Quantum Experience. Let's begin by importing the Quantum Swift Framework:
*/
import qiskit
import Cocoa
import PlaygroundSupport
import XCPlayground

/*:
[Quantum Experience web site]: https://www.research.ibm.com/ibm-q/ "IBM Quantum Experience"
 Before we can start running experiments on the Quantum Experience, the API needs to be configured with your personal APItoken. This is done by setting variables in the Qconfig API for accessing the Quantum Experience. You can begin by replacing "None" with your personal access token which you can obtain from the
 [Quantum Experience web site] under the Accounts button.
 */
var testurl = "https://quantumexperience.ng.bluemix.net/api/"
var apitoken = "None"

/*:
 ### Quantum Program
 The following code represents a quantum circuit and program. The basic elements that you need to create your first program are, the QuantumProgram, a Circuit, a Quantum Register and a Classical Register.
 */

/*:
 ### Quantum and Classical registers
 A Quantum Program can have several Quantum registers and several Classical Registers
 */
do {
    let q = try QuantumRegister("q", 5)
    let c = try ClassicalRegister("c", 5)

/*:
 ### Quantum Circuit
 The following code represents a quantum circuit
*/

    let circuit = try QuantumCircuit([q,c])

/*:
[Quantum Experience User Guide]: https://quantumexperience.ng.bluemix.net/qstage/#/tutorial?sectionId=71972f437b08e12d1f465a8857f4514c&pageIndex=2 "Quantum Experience User Guide"
 ### Add Gates to your Circuit
 After you create the circuit with its registers you can add gates to manipulate the registers.
 - You can find extensive information about these gates and how use it into our [Quantum Experience User Guide]
*/
    try circuit.x(q[0])
    try circuit.x(q[1])
    try circuit.h(q[2])
    try circuit.measure(q[0], c[0])
    try circuit.measure(q[1], c[1])
    try circuit.measure(q[2], c[2])
    try circuit.measure(q[3], c[3])
    try circuit.measure(q[4], c[4])

/*:
 ### Extracting Qasm
You obtain a QASM representation of your code by print your circuit any time as follows:
 */
    print(circuit.qasm())


/*:
 ### Execute your Program
 The following code initializes a quantum program compile, configures it with your API Token and API url, and runs the execution.
 */

    let qp = try QuantumProgram()
    qp.set_api(token: apitoken, url: testurl)
    try qp.add_circuit("test", circuit)

    qp.execute(["test"], backend: "ibmqx_qasm_simulator") { (result) in
        if let error = result.get_error() {
            print(error)
            return
        }
        do {
            print(try result.get_counts("test"))
        } catch {
            print(error)
        }
    }

} catch {
    print(error)
}


PlaygroundPage.current.needsIndefiniteExecution = true
