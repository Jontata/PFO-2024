import pandas as pd
import matplotlib.pyplot as plt

# Load data for Efficient Frontier
df = pd.read_excel('42MeanVarianceFrontier_EqDist.xls', index_col=0)
# Extract the data for plotting
variance = df.loc['Variance'].values
returns = df.loc['Return'].values

# Add points for specific portfolios

port_min_var_constraint = [0.00654481,0.20668661]

port_min_return_constraint = [0.00035247, 0.06414900]

port_current = [0.0809**2, 0.06414900]


# Plotting the efficient frontier
plt.figure(figsize=(10, 6))
# Plot the efficient frontier
plt.plot(variance, returns, marker='o', linestyle='-', color='b')
# Plot portfolios as points

#? Portfolio with minimum variance constraint
# plot the point
plt.plot(port_min_var_constraint[0], port_min_var_constraint[1], marker='o', markersize=8, color='r', label='Min Std Constraint Portfolio')
# make a line
plt.plot([port_min_var_constraint[0], port_min_var_constraint[0] + 0.002], 
         [port_min_var_constraint[1], port_min_var_constraint[1] - 0.01], 
         color='black', linestyle='-', linewidth=0.8)
# plot text
plt.text(port_min_var_constraint[0] + 0.022, port_min_var_constraint[1] - 0.016, 
         'Maximizing Return with STD Constraint', fontsize=10, ha='right')

#? Portfolio with minimum return constraint
# plot the point
plt.plot(port_min_return_constraint[0], port_min_return_constraint[1], marker='o', markersize=8, color='g', label='Min Return Constraint Portfolio')
# make a line
plt.plot([port_min_return_constraint[0], port_min_return_constraint[0] + 0.001], 
         [port_min_return_constraint[1], port_min_return_constraint[1] - 0.01], 
         color='black', linestyle='-', linewidth=0.8)
# plot text
plt.text(port_min_return_constraint[0] + 0.02, port_min_return_constraint[1] - 0.02, 
         'Minimizing STD with Return Constraint', fontsize=10, ha='right')

#? Current Portfolio
# plot the point
plt.plot(port_current[0], port_current[1], marker='o', markersize=8, color='y', label='Current Portfolio')
# make a line
plt.plot([port_current[0], port_current[0] + 0.002], 
         [port_current[1], port_current[1] - 0.01], 
         color='black', linestyle='-', linewidth=0.8)
# plot text
plt.text(port_current[0] + 0.0105, port_current[1] - 0.015, 
         'Current Portfolio', fontsize=10, ha='right')


# Set x and y axis limits
plt.xlim([-0.005, 0.0505])
plt.ylim([-0.005, 0.35])

plt.xlabel('Portfolio Variance')
plt.ylabel('Portfolio Return')
plt.grid(True)

# Save the plot as png file
plt.savefig('4_2_EfficientFrontier.png')

plt.show()