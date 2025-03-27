import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

# Parameters
filename = "system_properties_prod.dat"
rolling_window = 500

# Load and label data
df = pd.read_csv(filename, sep='\s+', comment='#', header=None)
df.columns = ['TimeStep', 'Volume', 'Density', 'TotalEnergy', 'PotEnergy', 'KinEnergy', 'Temperature', 'Pressure']

# Compute pressure mean for y-axis zoom
avg_pressure = df['Pressure'].mean()

# ========== PRESSURE ==========
plt.figure(figsize=(10, 6))
plt.plot(df['TimeStep'].to_numpy(),
         df['Pressure'].to_numpy(),
         label='Instantaneous Pressure',
         alpha=0.3, color='steelblue')

rolling_avg = df['Pressure'].rolling(
    window=rolling_window, win_type='gaussian', center=True).mean(std=rolling_window / 2)
plt.plot(df['TimeStep'].to_numpy(),
         rolling_avg.to_numpy(),
         label=f'Rolling Avg (window={rolling_window})',
         color='darkred', linewidth=2)

plt.axhline(avg_pressure, color='gray', linestyle='--', linewidth=1.5, label=f'Avg Pressure = {avg_pressure:.2f} atm')
plt.xlabel('Timestep')
plt.ylabel('Pressure (atm)')
plt.title('NPT Production Pressure (Smoothed)')
plt.legend()
plt.grid(True)
plt.ylim(avg_pressure - 100, avg_pressure + 100)
plt.tight_layout()
plt.savefig("npt_pressure_plot_smoothed.png", dpi=300)
plt.close()

# ========== VOLUME ==========
plt.figure(figsize=(10, 6))
rolling_avg = df['Volume'].rolling(
    window=rolling_window, win_type='gaussian', center=True).mean(std=rolling_window / 2)
plt.plot(df['TimeStep'].to_numpy(), df['Volume'].to_numpy(),
         label='Instantaneous Volume', alpha=0.3, color='green')
plt.plot(df['TimeStep'].to_numpy(), rolling_avg.to_numpy(),
         label='Smoothed Volume', color='darkgreen', linewidth=2)

plt.xlabel('Timestep')
plt.ylabel('Volume (Å³)')
plt.title('NPT Production Volume')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("npt_volume_plot_smoothed.png", dpi=300)
plt.close()

# ========== SIDE ==========
plt.figure(figsize=(10, 6))

box_side = df['Volume'] ** (1/3)
rolling_avg = box_side.rolling(
    window=rolling_window, win_type='gaussian', center=True).mean(std=rolling_window / 2)

plt.plot(df['TimeStep'].to_numpy(), box_side.to_numpy(),
         label='Instantaneous Box Side', alpha=0.3, color='blue')
plt.plot(df['TimeStep'].to_numpy(), rolling_avg.to_numpy(),
         label='Smoothed Box Side', color='darkblue', linewidth=2)

plt.xlabel('Timestep')
plt.ylabel('Box Side Length (Å)')
plt.title('NPT Production Box Side (Cube Root of Volume)')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("npt_boxside_plot_smoothed.png", dpi=300)
plt.close()

# ========== DENSITY ==========
plt.figure(figsize=(10, 6))
rolling_avg = df['Density'].rolling(
    window=rolling_window, win_type='gaussian', center=True).mean(std=rolling_window / 2)
plt.plot(df['TimeStep'].to_numpy(), df['Density'].to_numpy(),
         label='Instantaneous Density', alpha=0.3, color='purple')
plt.plot(df['TimeStep'].to_numpy(), rolling_avg.to_numpy(),
         label='Smoothed Density', color='indigo', linewidth=2)

plt.xlabel('Timestep')
plt.ylabel('Density (g/cm³)')
plt.title('NPT Production Density')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("npt_density_plot_smoothed.png", dpi=300)
plt.close()

# ========== TEMPERATURE ==========
plt.figure(figsize=(10, 6))
rolling_avg = df['Temperature'].rolling(
    window=rolling_window, win_type='gaussian', center=True).mean(std=rolling_window / 2)
plt.plot(df['TimeStep'].to_numpy(), df['Temperature'].to_numpy(),
         label='Instantaneous Temperature', alpha=0.3, color='orange')
plt.plot(df['TimeStep'].to_numpy(), rolling_avg.to_numpy(),
         label='Smoothed Temperature', color='darkorange', linewidth=2)

plt.xlabel('Timestep')
plt.ylabel('Temperature (K)')
plt.title('NPT Production Temperature')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("npt_temperature_plot_smoothed.png", dpi=300)
plt.close()

# ========== TOTAL ENERGY ==========
plt.figure(figsize=(10, 6))
rolling_avg = df['TotalEnergy'].rolling(
    window=rolling_window, win_type='gaussian', center=True).mean(std=rolling_window / 2)
plt.plot(df['TimeStep'].to_numpy(), df['TotalEnergy'].to_numpy(),
         label='Instantaneous Total Energy', alpha=0.3, color='brown')
plt.plot(df['TimeStep'].to_numpy(), rolling_avg.to_numpy(),
         label='Smoothed Total Energy', color='maroon', linewidth=2)

plt.xlabel('Timestep')
plt.ylabel('Total Energy (eV)')
plt.title('NPT Production Total Energy')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("npt_total_energy_plot_smoothed.png", dpi=300)
plt.close()

# ========== POTENTIAL ENERGY ==========
plt.figure(figsize=(10, 6))
rolling_avg = df['PotEnergy'].rolling(
    window=rolling_window, win_type='gaussian', center=True).mean(std=rolling_window / 2)
plt.plot(df['TimeStep'].to_numpy(), df['PotEnergy'].to_numpy(),
         label='Instantaneous Potential Energy', alpha=0.3, color='teal')
plt.plot(df['TimeStep'].to_numpy(), rolling_avg.to_numpy(),
         label='Smoothed Potential Energy', color='darkslategray', linewidth=2)

plt.xlabel('Timestep')
plt.ylabel('Potential Energy (eV)')
plt.title('NPT Production Potential Energy')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("npt_pot_energy_plot_smoothed.png", dpi=300)
plt.close()

# ========== KINETIC ENERGY ==========
plt.figure(figsize=(10, 6))
rolling_avg = df['KinEnergy'].rolling(
    window=rolling_window, win_type='gaussian', center=True).mean(std=rolling_window / 2)
plt.plot(df['TimeStep'].to_numpy(), df['KinEnergy'].to_numpy(),
         label='Instantaneous Kinetic Energy', alpha=0.3, color='deepskyblue')
plt.plot(df['TimeStep'].to_numpy(), rolling_avg.to_numpy(),
         label='Smoothed Kinetic Energy', color='dodgerblue', linewidth=2)

plt.xlabel('Timestep')
plt.ylabel('Kinetic Energy (eV)')
plt.title('NPT Production Kinetic Energy')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("npt_kin_energy_plot_smoothed.png", dpi=300)
plt.close()

