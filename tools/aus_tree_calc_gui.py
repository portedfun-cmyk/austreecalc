#!/usr/bin/env python3
"""Simple desktop GUI for the AusTreeCalc Python engine.

Usage (from project root):

    python3 tools/aus_tree_calc_gui.py

This opens a window where you can:
- Enter tree + wind + cavity + defect info.
- Click "Run calculation & build Word report".
- The script will write a .docx report with graphs next to this file.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import tkinter as tk
from tkinter import ttk, messagebox

from aus_tree_calc_standalone import (
    SPECIES_PRESETS,
    SpeciesPreset,
    calculate_single,
    compute_defect_strength_factor,
    estimate_wind_to_failure,
    residual_wall_fraction,
    build_sf_vs_wind_curve,
    build_sf_vs_residual_wall_curve,
    build_sf_vs_crown_reduction_curve,
    build_word_report_from_python,
    CalcResult,
)


class AusTreeCalcGUI(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("AusTreeCalc – Desktop")
        self.geometry("820x640")

        self._build_state()
        self._build_widgets()

    # ---------------- State helpers -----------------
    def _build_state(self) -> None:
        # Identity
        self.tree_label_var = tk.StringVar(value="Tree 1")
        self.site_location_var = tk.StringVar(value="")

        # Species
        self.species_var = tk.StringVar(value=SPECIES_PRESETS[1].id)

        # Numeric inputs
        self.dbh_var = tk.StringVar(value="50")
        self.height_var = tk.StringVar(value="18")
        self.crown_var = tk.StringVar(value="10")
        self.cavity_var = tk.StringVar(value="")
        self.wind_var = tk.StringVar(value="40")
        self.site_factor_var = tk.StringVar(value="1.0")

        self.use_fullness_override_var = tk.BooleanVar(value=False)
        self.fullness_var = tk.StringVar(value="0.9")

        # Defects
        self.def_bracket_var = tk.BooleanVar(value=False)
        self.def_cavity_decay_var = tk.BooleanVar(value=False)
        self.def_cracks_var = tk.BooleanVar(value=False)
        self.def_basal_var = tk.BooleanVar(value=False)
        self.def_union_var = tk.BooleanVar(value=False)
        self.def_other_var = tk.StringVar(value="")

        # Pruning modelling
        self.crown_reduction_base_var = tk.StringVar(value="20")
        self.fullness_reduction_var = tk.StringVar(value="30")

        # Output text
        self._last_result: CalcResult | None = None

    # ---------------- UI construction -----------------
    def _build_widgets(self) -> None:
        container = ttk.Frame(self, padding=10)
        container.pack(fill=tk.BOTH, expand=True)

        # Use grid with two columns
        container.columnconfigure(0, weight=1)
        container.columnconfigure(1, weight=1)

        # Tree / site panel
        tree_frame = ttk.LabelFrame(container, text="Tree & site")
        tree_frame.grid(row=0, column=0, sticky="nsew", padx=4, pady=4)
        tree_frame.columnconfigure(1, weight=1)

        ttk.Label(tree_frame, text="Tree label / ID:").grid(row=0, column=0, sticky="w")
        ttk.Entry(tree_frame, textvariable=self.tree_label_var).grid(
            row=0, column=1, sticky="ew", pady=2
        )

        ttk.Label(tree_frame, text="Site / location:").grid(row=1, column=0, sticky="w")
        ttk.Entry(tree_frame, textvariable=self.site_location_var).grid(
            row=1, column=1, sticky="ew", pady=2
        )

        ttk.Label(tree_frame, text="Species preset:").grid(row=2, column=0, sticky="w")
        species_combo = ttk.Combobox(
            tree_frame,
            textvariable=self.species_var,
            state="readonly",
            values=[sp.id for sp in SPECIES_PRESETS],
        )
        species_combo.grid(row=2, column=1, sticky="ew", pady=2)
        species_combo.bind("<<ComboboxSelected>>", self._on_species_change)
        # Show human-readable names as tooltip-ish text via label
        self.species_desc_label = ttk.Label(
            tree_frame, text=SPECIES_PRESETS[1].name, wraplength=340
        )
        self.species_desc_label.grid(row=3, column=0, columnspan=2, sticky="w", pady=2)

        # Geometry / wind panel
        geo_frame = ttk.LabelFrame(container, text="Geometry & wind")
        geo_frame.grid(row=0, column=1, sticky="nsew", padx=4, pady=4)
        geo_frame.columnconfigure(1, weight=1)

        def _add_row(label: str, var: tk.StringVar, row: int, unit: str = "") -> None:
            ttk.Label(geo_frame, text=label).grid(row=row, column=0, sticky="w")
            entry = ttk.Entry(geo_frame, textvariable=var, width=10)
            entry.grid(row=row, column=1, sticky="w", pady=2)
            if unit:
                ttk.Label(geo_frame, text=unit).grid(row=row, column=2, sticky="w")

        _add_row("DBH:", self.dbh_var, 0, "cm")
        _add_row("Height:", self.height_var, 1, "m")
        _add_row("Crown diameter:", self.crown_var, 2, "m")
        _add_row("Cavity inner diameter:", self.cavity_var, 3, "cm")
        _add_row("Design wind speed:", self.wind_var, 4, "m/s")
        _add_row("Site factor:", self.site_factor_var, 5, "0.5–1.5")

        fullness_check = ttk.Checkbutton(
            geo_frame,
            text="Override crown fullness",
            variable=self.use_fullness_override_var,
        )
        fullness_check.grid(row=6, column=0, columnspan=2, sticky="w", pady=4)
        ttk.Entry(geo_frame, textvariable=self.fullness_var, width=6).grid(
            row=6, column=2, sticky="w", pady=4
        )

        # Defects panel
        defects_frame = ttk.LabelFrame(container, text="Defects / decay")
        defects_frame.grid(row=1, column=0, sticky="nsew", padx=4, pady=4)
        for i in range(2):
            defects_frame.columnconfigure(i, weight=1)

        ttk.Checkbutton(
            defects_frame,
            text="Bracket fungi on stem or base",
            variable=self.def_bracket_var,
        ).grid(row=0, column=0, columnspan=2, sticky="w")
        ttk.Checkbutton(
            defects_frame,
            text="Cavity with visible decay",
            variable=self.def_cavity_decay_var,
        ).grid(row=1, column=0, columnspan=2, sticky="w")
        ttk.Checkbutton(
            defects_frame,
            text="Longitudinal cracks / shear planes",
            variable=self.def_cracks_var,
        ).grid(row=2, column=0, columnspan=2, sticky="w")
        ttk.Checkbutton(
            defects_frame,
            text="Basal/root-plate decay symptoms",
            variable=self.def_basal_var,
        ).grid(row=3, column=0, columnspan=2, sticky="w")
        ttk.Checkbutton(
            defects_frame,
            text="Included bark / compromised unions",
            variable=self.def_union_var,
        ).grid(row=4, column=0, columnspan=2, sticky="w")

        ttk.Label(defects_frame, text="Other observations:").grid(
            row=5, column=0, sticky="nw", pady=(4, 0)
        )
        ttk.Entry(defects_frame, textvariable=self.def_other_var).grid(
            row=5, column=1, sticky="ew", pady=(4, 0)
        )

        # Pruning panel
        pruning_frame = ttk.LabelFrame(container, text="Pruning / mitigation modelling")
        pruning_frame.grid(row=1, column=1, sticky="nsew", padx=4, pady=4)
        pruning_frame.columnconfigure(1, weight=1)

        ttk.Label(pruning_frame, text="Typical crown reduction (%):").grid(
            row=0, column=0, sticky="w"
        )
        ttk.Entry(pruning_frame, textvariable=self.crown_reduction_base_var, width=6).grid(
            row=0, column=1, sticky="w", pady=2
        )

        ttk.Label(pruning_frame, text="Typical thinning / fullness reduction (%):").grid(
            row=1, column=0, sticky="w"
        )
        ttk.Entry(pruning_frame, textvariable=self.fullness_reduction_var, width=6).grid(
            row=1, column=1, sticky="w", pady=2
        )

        # Actions + output
        bottom_frame = ttk.Frame(container)
        bottom_frame.grid(row=2, column=0, columnspan=2, sticky="nsew", pady=(8, 0))
        bottom_frame.columnconfigure(0, weight=1)

        btn_frame = ttk.Frame(bottom_frame)
        btn_frame.grid(row=0, column=0, sticky="w")

        run_btn = ttk.Button(
            btn_frame,
            text="Run calculation & build Word report",
            command=self._on_run,
        )
        run_btn.grid(row=0, column=0, padx=(0, 8))

        quit_btn = ttk.Button(btn_frame, text="Quit", command=self.destroy)
        quit_btn.grid(row=0, column=1)

        # Output text area
        self.output_text = tk.Text(
            bottom_frame,
            height=10,
            wrap="word",
        )
        self.output_text.grid(row=1, column=0, sticky="nsew", pady=(6, 0))
        bottom_frame.rowconfigure(1, weight=1)

    # ---------------- Event handlers -----------------
    def _on_species_change(self, _event=None) -> None:  # noqa: ANN001
        sp = self._get_species()
        self.species_desc_label.config(text=sp.name)
        # Also update fullness default display
        if not self.use_fullness_override_var.get():
            self.fullness_var.set(f"{sp.default_fullness:.2f}")

    def _get_species(self) -> SpeciesPreset:
        sid = self.species_var.get()
        for sp in SPECIES_PRESETS:
            if sp.id == sid:
                return sp
        return SPECIES_PRESETS[1]

    def _parse_float(self, value: str, name: str) -> float | None:
        try:
            v = float(value.replace(",", "."))
        except ValueError:
            messagebox.showerror("Input error", f"{name} must be a number.")
            return None
        if v <= 0:
            messagebox.showerror("Input error", f"{name} must be > 0.")
            return None
        return v

    def _parse_optional_float(self, value: str) -> float | None:
        v = value.strip()
        if not v:
            return None
        try:
            num = float(v.replace(",", "."))
        except ValueError:
            return None
        if num <= 0:
            return None
        return num

    def _append_output(self, text: str) -> None:
        self.output_text.insert(tk.END, text + "\n")
        self.output_text.see(tk.END)

    def _on_run(self) -> None:
        # Parse inputs
        sp = self._get_species()

        dbh = self._parse_float(self.dbh_var.get(), "DBH")
        height = self._parse_float(self.height_var.get(), "Height")
        crown = self._parse_float(self.crown_var.get(), "Crown diameter")
        wind = self._parse_float(self.wind_var.get(), "Design wind speed")
        site_factor = self._parse_float(self.site_factor_var.get(), "Site factor")
        if None in (dbh, height, crown, wind, site_factor):
            return
        assert dbh is not None and height is not None and crown is not None
        assert wind is not None and site_factor is not None

        cavity = self._parse_optional_float(self.cavity_var.get())

        fullness_override = None
        if self.use_fullness_override_var.get():
            f = self._parse_float(self.fullness_var.get(), "Fullness override")
            if f is None:
                return
            fullness_override = max(0.1, min(1.0, f))

        crown_red_base = self._parse_float(
            self.crown_reduction_base_var.get(), "Crown reduction (%)"
        )
        fullness_red = self._parse_float(
            self.fullness_reduction_var.get(), "Fullness reduction (%)"
        )
        if crown_red_base is None or fullness_red is None:
            return

        # Defect factors
        k_defect = compute_defect_strength_factor(
            self.def_bracket_var.get(),
            self.def_cavity_decay_var.get(),
            self.def_cracks_var.get(),
            self.def_basal_var.get(),
            self.def_union_var.get(),
        )

        # Core calculation
        result = calculate_single(
            sp,
            dbh,
            height,
            crown,
            wind,
            cavity,
            fullness_override,
            site_factor,
            k_defect,
        )
        self._last_result = result

        wind_to_failure = estimate_wind_to_failure(
            sp,
            dbh,
            height,
            crown,
            wind,
            cavity,
            fullness_override,
            site_factor,
            k_defect,
        )

        # Curves
        sf_wind_x, sf_wind_y = build_sf_vs_wind_curve(
            sp,
            dbh,
            height,
            crown,
            wind,
            cavity,
            fullness_override,
            site_factor,
            k_defect,
            wind_to_failure,
        )
        rw_x, rw_y, crit_rw, crit_wall = build_sf_vs_residual_wall_curve(
            sp,
            dbh,
            height,
            crown,
            wind,
            fullness_override,
            site_factor,
            k_defect,
        )
        red_x, red_y = build_sf_vs_crown_reduction_curve(
            sp,
            dbh,
            height,
            crown,
            wind,
            cavity,
            fullness_override,
            site_factor,
            k_defect,
            crown_red_base,
            fullness_red,
        )

        tree_label = self.tree_label_var.get().strip() or "Tree 1"
        site_location = self.site_location_var.get().strip()

        # Prepare dictionaries to feed into the existing Word-report builder
        inputs = {
            "dbh_cm": dbh,
            "height_m": height,
            "crown_diameter_m": crown,
            "cavity_inner_diameter_cm": cavity,
            "design_wind_speed_ms": wind,
            "site_factor": site_factor,
        }
        defects = {
            "bracket_fungi": self.def_bracket_var.get(),
            "cavity_decay": self.def_cavity_decay_var.get(),
            "cracks": self.def_cracks_var.get(),
            "basal_decay": self.def_basal_var.get(),
            "union": self.def_union_var.get(),
            "other": self.def_other_var.get().strip(),
            "strength_factor_k_defect": k_defect,
        }
        res_wall_frac = residual_wall_fraction(dbh, cavity)
        res_wall_pct = res_wall_frac * 100.0
        decay_info = {
            "current_residual_percent": res_wall_pct,
            "critical_residual_percent": crit_rw,
            "critical_wall_thickness_cm": crit_wall,
        }
        graphs = {
            "sf_vs_wind": {"x": sf_wind_x, "y": sf_wind_y},
            "sf_vs_residual_wall": {"x": rw_x, "y": rw_y},
            "sf_vs_crown_reduction": {"x": red_x, "y": red_y},
        }

        script_dir = Path(__file__).resolve().parent
        output_doc = script_dir / "aus_tree_calc_report_gui.docx"

        build_word_report_from_python(
            output_doc,
            tree_label,
            sp,
            site_location,
            inputs,
            defects,
            result,
            wind_to_failure,
            decay_info,
            graphs,
        )

        # Update output text
        self.output_text.delete("1.0", tk.END)
        self._append_output(f"Tree: {tree_label} ({sp.name})")
        if site_location:
            self._append_output(f"Location: {site_location}")
        self._append_output(
            f"Safety factor SF at design wind: "
            f"{result.safety_factor:.2f}" if math.isfinite(result.safety_factor) else "SF: ∞"
        )
        self._append_output(f"Bending stress: {result.bending_stress_mpa:.2f} MPa")
        if wind_to_failure is not None and math.isfinite(wind_to_failure):
            self._append_output(
                f"Estimated wind-to-failure (SF ≈ 1): {wind_to_failure:.1f} m/s"
            )
        self._append_output(
            f"Current residual wall: {res_wall_pct:.0f}% of diameter"
        )
        if crit_rw is not None and crit_wall is not None:
            self._append_output(
                "SF ≈ 1 at residual wall ≈ "
                f"{crit_rw:.0f}% (≈ {crit_wall:.1f} cm on each side)"
            )
        self._append_output("")
        self._append_output(f"Word report written to: {output_doc}")
        messagebox.showinfo(
            "AusTreeCalc",
            f"Calculation complete. Word report written to:\n{output_doc}",
        )


def main(argv: list[str]) -> int:  # noqa: D401
    """Run the AusTreeCalc GUI application."""
    app = AusTreeCalcGUI()
    app.mainloop()
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main(sys.argv))
