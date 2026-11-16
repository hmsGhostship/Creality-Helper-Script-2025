#!/usr/bin/env python3
import csv, math, os, sys

def fft_mag(samples):
    n = 1
    while n < len(samples):
        n <<= 1
    if n > 4096:
        n = 4096
    x = [complex(samples[i], 0.0) if i < len(samples) else 0j for i in range(n)]
    j = 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            x[i], x[j] = x[j], x[i]
    step = 2
    while step <= n:
        half = step >> 1
        ang = -2.0 * math.pi / step
        w_step = complex(math.cos(ang), math.sin(ang))
        for k in range(0, n, step):
            w = 1.0 + 0j
            for m in range(half):
                u = x[k + m]
                v = x[k + m + half] * w
                x[k + m] = u + v
                x[k + m + half] = u - v
                w *= w_step
        step <<= 1
    return [abs(x[i]) / n for i in range(n // 2)]

def parse_csv(path):
    if not os.path.exists(path):
        return [], []
    freqs, vals = [], []
    with open(path, "r") as f:
        rows = [r for r in csv.reader(f) if r and not r.startswith("#")]
    if not rows:
        return [], []
    try:
        float(rows)
        data_rows = rows
    except ValueError:
        header = [h.strip().lower() for h in rows]
        data_rows = rows[1:]
        if "freq" in header:
            fi = header.index("freq")
            vi = header.index("psd_xyz") if "psd_xyz" in header else len(header) - 1
            for r in data_rows:
                if len(r) > max(fi, vi):
                    freqs.append(float(r[fi]))
                    vals.append(float(r[vi]))
            return freqs, vals
    times, acc = [], []
    for r in data_rows:
        if len(r) >= 4:
            t = float(r)
            ax, ay, az = float(r), float(r), float(r)
            times.append(t)
            acc.append(math.sqrt(ax*ax + ay*ay + az*az))
    if len(times) < 32:
        return [], []
    mean = sum(acc) / len(acc)
    acc = [a - mean for a in acc]
    dt = (times[-1] - times) / max(1, len(times) - 1)
    fs = 1.0 / dt if dt > 0 else 3200.0
    mags = fft_mag(acc)
    n_fft = len(mags) * 2
    for i, m in enumerate(mags):
        freq = i * fs / n_fft
        if 5.0 <= freq <= 140.0:
            freqs.append(freq)
            vals.append(m)
    return freqs, vals

def write_svg(out_path, series, title):
    w, h = 840, 440
    pad_l, pad_r, pad_t, pad_b = 65, 25, 45, 50
    pw, ph = w - pad_l - pad_r, h - pad_t - pad_b
    max_y = max([max(v) for _, _, v, _ in series if v] + [1e-6])
    colors = ["#2563eb", "#dc2626", "#16a34a"]
    lines = [
        f"<svg xmlns="http://w3.org" width="{w}" height="{h}" style="background:#0f172a;font-family:sans-serif">",
        f"<text x="{w//2}" y="26" fill="#f8fafc" font-size="16" font-weight="bold" text-anchor="middle">{title}</text>"
    ]
    for gx in range(10, 141, 10):
        x = pad_l + (gx - 5.0) / 135.0 * pw
        lines.append(f"<line x1="{x:.1f}" y1="{pad_t}" x2="{x:.1f}" y2="{pad_t+ph}" stroke="#1e293b" stroke-width="1"/>")
        lines.append(f"<text x="{x:.1f}" y="{h-22}" fill="#94a3b8" font-size="11" text-anchor="middle">{gx}</text>")
    lines.append(f"<text x="{w//2}" y="{h-5}" fill="#cbd5e1" font-size="12" text-anchor="middle">Frequency (Hz)</text>")
    for idx, (label, freqs, vals, peak_txt) in enumerate(series):
        if not freqs:
            continue
        col = colors[idx % len(colors)]
        pts = []
        for f, v in zip(freqs, vals):
            if 5.0 <= f <= 140.0:
                x = pad_l + (f - 5.0) / 135.0 * pw
                y = pad_t + ph - (v / max_y) * ph
                pts.append(f"{x:.1f},{y:.1f}")
        lines.append(f"<polyline fill="none" stroke="{col}" stroke-width="2" points="{" ".join(pts)}"/>")
        lines.append(f"<text x="{pad_l + 10}" y="{pad_t + 18 + idx*18}" fill="{col}" font-size="12" font-weight="bold">{label}{peak_txt}</text>")
    lines.append("</svg>")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write("\n".join(lines))

def main():
    args = sys.argv[1:]
    out_path = ""
    csv_files = []
    i = 0
    while i < len(args):
        if args[i] == "-o" and i + 1 < len(args):
            out_path = args[i + 1]
            i += 2
        elif args[i] in ("-w", "-l", "-k") and i + 1 < len(args):
            i += 2
        elif args[i].startswith("-"):
            i += 1
        else:
            csv_files.append(args[i])
            i += 1
    if not out_path or not csv_files:
        sys.exit(1)
    series = []
    for cf in csv_files:
        freqs, vals = parse_csv(cf)
        peak_txt = ""
        if freqs and vals:
            mi = max(range(len(vals)), key=lambda k: vals[k])
            peak_txt = f" (Peak: {freqs[mi]:.1f} Hz)"
        series.append((os.path.basename(cf), freqs, vals, peak_txt))
    title = "Belts Frequency Spectrum" if len(csv_files) > 1 else f"Resonance Spectrum ({os.path.basename(out_path)})"
    write_svg(out_path, series, title)
    print(f"Generated SVG spectrum: {out_path}")

if __name__ == "__main__":
    main()
