# Tree Calculator

A simple command-line tool for calculating tree measurements and statistics.

## Features

- Calculate tree volume
- Estimate tree biomass
- Visualize tree measurements
- Support for multiple tree species

## Installation

1. Clone this repository
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

Run the calculator:
```bash
python tree_calculator.py
```

## Example

```python
# Create some trees
tree1 = Tree(height=15.0, diameter=30.5, species="Oak")
tree2 = Tree(height=12.5, diameter=25.0, species="Pine")

# Calculate volume and biomass
print(f"Volume: {tree1.calculate_volume():.2f} m³")
print(f"Biomass: {tree1.calculate_biomass():.2f} kg")
```

## License

MIT
