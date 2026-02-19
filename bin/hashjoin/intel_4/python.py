import numpy as np
import matplotlib.pyplot as plt

# ── Raw data (5 runs each) ──────────────────────────────────────────────

data = {
    "Linux": {
        "regular": {
            "cycles": [23538089414360, 25919573241396, 26095831580436, 26018246995476, 26089955297829],
            "dtlb_load": [6393624297793, 6910891870789, 6972768913258, 6945726192473, 6954288887970],
        },
        "interleave": {
            "cycles": [17113366213814, 17127106290889, 17191186911184, 17164702557631, 17159190329938],
            "dtlb_load": [4557726871097, 4575162226120, 4594837187552, 4593637075225, 4582295450218],
        },
    },
    "Mitosis": {
        "regular": {
            "cycles": [19819900938781, 19945848108304, 18826254032296, 19255522752884, 19494739079568],
            "dtlb_load": [2998142200809, 2908201798929, 2901727674123, 2908842722542, 2900792295200],
        },
        "interleave": {
            "cycles": [14411814655930, 14380113567726, 14413050400995, 14372515201011, 14417933703073],
            "dtlb_load": [2736228057388, 2728911009317, 2730311158054, 2731049963899, 2730807566526],
        },
    },
    "Hydra": {
        "regular": {
            "cycles": [17394607219888, 19892264118529, 18886564317358, 18844329576668, 18943009639061],
            "dtlb_load": [2693996754838, 2856654813042, 2848537607598, 2847188590749, 2880453922487],
        },
        "interleave": {
            "cycles": [14354746398533, 14374132025516, 14384665827687, 14368306602166, 14376181803952],
            "dtlb_load": [2744570531296, 2747580717446, 2736747331961, 2753180040036, 2760731347632],
        },
    },
    "WASP": {
        "regular": {
            "cycles": [20474129003585, 19452788426121, 14477104635414, 18113135132463, 19632799967282],
            "dtlb_load": [3064901645074, 3053070916911, 2094034460044, 2796208861480, 2986036491440],
        },
        "interleave": {
            "cycles": [14289641448343, 14089764218420, 14299669350657, 14043354996931, 14067289120237],
            "dtlb_load": [2780067126859, 2721632672197, 2783166207702, 2709156246622, 2717088643303],
        },
    },
}

systems = list(data.keys())

# ── Convert MRS from megabytes to gigabytes ─────────────────────────────

mrs_mb = 82397 + 2059 + 1029  # = 85485 MB
mrs_gb = mrs_mb / 1024  # ≈ 83.5 GB

# ── Compute means, normalize to Linux ───────────────────────────────────

means = {}
for s in systems:
    means[s] = {}
    for v in ("regular", "interleave"):
        walks  = np.array(data[s][v]["dtlb_load"])
        cycles = np.array(data[s][v]["cycles"])
        other  = cycles - walks
        means[s][v] = {"walk": np.mean(walks), "other": np.mean(other), "total": np.mean(cycles)}

norm = {}
for s in systems:
    norm[s] = {}
    for v in ("regular", "interleave"):
        base = means["Linux"][v]["total"]
        total_n = means[s][v]["total"] / base
        fw = means[s][v]["walk"]  / means[s][v]["total"]
        fo = means[s][v]["other"] / means[s][v]["total"]
        norm[s][v] = {"walk": total_n * fw, "other": total_n * fo, "total": total_n}

# ── Plot ────────────────────────────────────────────────────────────────

fig, axes = plt.subplots(1, 2, figsize=(14, 6), sharey=True)

c_walk  = "#C0392B"
c_other = "#2C3E50"
width   = 0.52

variant_titles = {"regular": "Regular", "interleave": "Interleave"}

for ax, v in zip(axes, ("regular", "interleave")):
    x = np.arange(len(systems))

    others = [norm[s][v]["other"] for s in systems]
    walks  = [norm[s][v]["walk"]  for s in systems]
    totals = [norm[s][v]["total"] for s in systems]

    ax.bar(x, others, width, label="Compute", color=c_other, edgecolor="white", linewidth=0.5)
    ax.bar(x, walks, width, bottom=others, label="Page Table Walks", color=c_walk, edgecolor="white", linewidth=0.5)

    # Walk % inside red portion
    for j, (w, o, t) in enumerate(zip(walks, others, totals)):
        pct = w / t * 100
        ax.text(x[j], o + w / 2, f"{pct:.0f}%", ha="center", va="center",
                fontsize=10, fontweight="bold", color="white")

    # Total label on top
    for j, t in enumerate(totals):
        ax.text(x[j], t + 0.015, f"{t:.2f}", ha="center", va="bottom",
                fontsize=9.5, fontweight="bold")

    ax.set_title(variant_titles[v], fontsize=13, fontweight="bold")
    ax.set_xticks(x)
    ax.set_xticklabels(systems, fontsize=11, fontweight="bold")
    ax.axhline(1.0, color="gray", linestyle="--", linewidth=0.8, alpha=0.6)
    ax.grid(axis="y", alpha=0.2)
    ax.set_axisbelow(True)
    ax.legend(fontsize=10, loc="lower left")

axes[0].set_ylabel("Normalized Cycles (Linux = 1.0)", fontsize=11)
axes[1].set_ylim(0, 1.1)

fig.suptitle(f"Hashjoin MRS {mrs_gb:.1f} GB (Intel 4 Socket, n=5) — Cycles Breakdown\n"
             "(each panel normalized to its own Linux baseline)",
             fontsize=14, fontweight="bold")
plt.tight_layout()
plt.savefig("hashjoin_normalized_breakdown.png", dpi=200, bbox_inches="tight")
plt.show()
print("Saved to hashjoin_normalized_breakdown.png")
