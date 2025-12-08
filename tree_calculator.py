import math

class TreeCalculator:
    """
    A calculator for various tree-related calculations.
    """
    
    @staticmethod
    def calculate_tree_volume(height_m: float, diameter_cm: float, tree_factor: float = 0.5) -> float:
        """
        Calculate the volume of a tree in cubic meters.
        
        Args:
            height_m: Height of the tree in meters
            diameter_cm: Diameter at breast height (DBH) in centimeters
            tree_factor: Shape factor (default 0.5 for most conifers)
            
        Returns:
            Volume in cubic meters
        """
        radius_m = (diameter_cm / 100) / 2  # Convert cm to m and get radius
        cross_section = math.pi * (radius_m ** 2)
        return cross_section * height_m * tree_factor
    
    @staticmethod
    def estimate_carbon_storage(volume_m3: float, wood_density_kg_m3: float = 500) -> float:
        """
        Estimate carbon storage in a tree.
        
        Args:
            volume_m3: Volume of the tree in cubic meters
            wood_density_kg_m3: Wood density in kg/m³ (default 500 kg/m³ for softwood)
            
        Returns:
            Carbon storage in kilograms
        """
        # Carbon content is about 50% of dry wood mass
        dry_wood_mass_kg = volume_m3 * wood_density_kg_m3
        return dry_wood_mass_kg * 0.5
    
    @staticmethod
    def tree_age_estimate(species: str, diameter_cm: float) -> float:
        """
        Estimate tree age based on species and diameter.
        
        Args:
            species: Tree species (e.g., 'oak', 'pine', 'eucalyptus')
            diameter_cm: Diameter at breast height in cm
            
        Returns:
            Estimated age in years
        """
        growth_rates = {
            'oak': 0.5,        # cm/year
            'pine': 1.0,       # cm/year
            'eucalyptus': 2.0, # cm/year
            'maple': 0.6,      # cm/year
            'spruce': 0.8      # cm/year
        }
        
        growth_rate = growth_rates.get(species.lower(), 0.7)  # Default to 0.7 cm/year
        return diameter_cm / growth_rate


def main():
    # Example usage
    calculator = TreeCalculator()
    
    # Example tree measurements
    height = 20  # meters
    diameter = 50  # cm
    species = 'oak'
    
    # Calculate metrics
    volume = calculator.calculate_tree_volume(height, diameter)
    carbon = calculator.estimate_carbon_storage(volume)
    age = calculator.tree_age_estimate(species, diameter)
    
    print(f"Tree Analysis for {species.capitalize()}:")
    print(f"- Height: {height} m")
    print(f"- Diameter: {diameter} cm")
    print(f"- Estimated Volume: {volume:.2f} m³")
    print(f"- Estimated Carbon Storage: {carbon:.1f} kg")
    print(f"- Estimated Age: {age:.1f} years")


if __name__ == "__main__":
    main()
