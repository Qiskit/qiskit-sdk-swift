# Visualizing a Quantum State (for Linux)
The latest version of this demo app is available on [QISKit Swift Tutorial](https://github.com/QISKit/qiskit-sdk-swift/tree/master/tutorial).

## Acknowledgement
This app is based on the playground with the same name located [here](https://github.com/QISKit/qiskit-sdk-swift/tree/master/tutorial/VisualizingQuantumState.playground), which in turn is based on [this notebook on QISKit Python Tutorial](https://github.com/QISKit/qiskit-tutorial/blob/master/1_introduction/visualizing_quantum_state.ipynb).

## Usage

```
swift run
```

This app will present a window with multiple tabs, one for each graph used to visualize information about the quantum state.

For a better understanding of what is going on, we recommend to study the documentation in the [notebook mentioned before](https://github.com/QISKit/qiskit-tutorial/blob/master/1_introduction/visualizing_quantum_state.ipynb).

Each graph is a GTK Widget, check [this file](https://github.com/QISKit/qiskit-sdk-swift/tree/master/tutorial/VisualizingQuantumState-Linux/Sources/VisualizingQuantumState-Linux/widgets.swift) to know how to handle a widget in your Swift app for Linux.