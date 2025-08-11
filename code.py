import pandas as pd
from sqlalchemy import create_engine
import urllib.parse
import matplotlib.pyplot as plt
import seaborn as sns

# MySQL connection details
username = "root"
password = urllib.parse.quote_plus("Midhun@123")  # URL-encode special characters
host = "localhost"
port = "3306"
database = "fashion_europe_2025"

# Create the connection engine
engine = create_engine(f"mysql+mysqlconnector://{username}:{password}@{host}:{port}/{database}")

# Test the connection by loading one table
dim_products_df = pd.read_sql("SELECT * FROM dim_products", con=engine)
print(dim_products_df.head())


dim_products_df = pd.read_sql("SELECT * FROM dim_products", con=engine)
fact_sales_df = pd.read_sql("SELECT * FROM fact_sales", con=engine)
dim_channels_df = pd.read_sql("SELECT * FROM dim_channels", con=engine)
dim_campaigns_df = pd.read_sql("SELECT * FROM dim_campaigns", con=engine)

merged_df = fact_sales_df.merge(dim_products_df, on="product_id", how="left") \
                         .merge(dim_channels_df, on="channel_id", how="left") \
                         .merge(dim_campaigns_df, on="campaign_id", how="left")

sns.set_theme(style="whitegrid")

# Channel Performance Analysis
channel_performance = merged_df.groupby('channel_name').agg(
    total_revenue=pd.NamedAgg(column='item_total', aggfunc='sum'),
    total_quantity=pd.NamedAgg(column='quantity', aggfunc='sum'),
    avg_order_value=pd.NamedAgg(column='item_total', aggfunc='mean')
).reset_index()

channel_performance = channel_performance.sort_values(by='total_revenue', ascending=False)
print(channel_performance)

plt.figure(figsize=(8,5))
sns.barplot(data=channel_performance, x="total_revenue", y="channel_name", palette="viridis")
plt.title("Total Revenue by Channel")
plt.xlabel("Total Revenue")
plt.ylabel("Channel")
plt.show()

# Campaign Performance
campaign_performance = merged_df.groupby('campaign_name').agg(
    total_revenue=pd.NamedAgg(column='item_total', aggfunc='sum'),
    total_quantity=pd.NamedAgg(column='quantity', aggfunc='sum')
).reset_index()

campaign_performance = campaign_performance.sort_values(by='total_revenue', ascending=False)

print("\nCampaign Performance:\n", campaign_performance)
plt.figure(figsize=(8,5))
sns.barplot(data=campaign_performance, x="total_revenue", y="campaign_name", palette="mako")
plt.title("Total Revenue by Campaign")
plt.xlabel("Total Revenue")
plt.ylabel("Campaign")
plt.show()

# Top Products by Revenue & Quantity
top_products = merged_df.groupby('product_name').agg(
    total_revenue=pd.NamedAgg(column='item_total', aggfunc='sum'),
    total_quantity=pd.NamedAgg(column='quantity', aggfunc='sum')
).reset_index()

top_products_by_revenue = top_products.sort_values(by='total_revenue', ascending=False).head(10)
top_products_by_quantity = top_products.sort_values(by='total_quantity', ascending=False).head(10)

print("\nTop Products by Revenue:\n", top_products_by_revenue)
print("\nTop Products by Quantity:\n", top_products_by_quantity)

plt.figure(figsize=(10,6))
sns.barplot(data=top_products_by_revenue, x="total_revenue", y="product_name", palette="plasma")
plt.title("Top 10 Products by Revenue")
plt.xlabel("Total Revenue")
plt.ylabel("Product")
plt.show()

plt.figure(figsize=(10,6))
sns.barplot(data=top_products_by_quantity, x="total_quantity", y="product_name", palette="cividis")
plt.title("Top 10 Products by Quantity Sold")
plt.xlabel("Total Quantity Sold")
plt.ylabel("Product")
plt.show()

# Create price bands
def price_band(price):
    if price < 50:
        return "Low"
    elif 50 <= price < 100:
        return "Medium"
    else:
        return "High"

merged_df['price_band'] = merged_df['unit_price'].apply(price_band)

# Profit margin
merged_df['profit_margin'] = merged_df['unit_price'] - merged_df['cost_price']

price_band_performance = merged_df.groupby('price_band').agg(
    avg_margin=pd.NamedAgg(column='profit_margin', aggfunc='mean'),
    total_revenue=pd.NamedAgg(column='item_total', aggfunc='sum'),
    total_quantity=pd.NamedAgg(column='quantity', aggfunc='sum')
).reset_index()

print("\nPrice Band & Profitability:\n", price_band_performance)

plt.figure(figsize=(7,5))
sns.barplot(data=price_band_performance, x="price_band", y="total_revenue", palette="coolwarm")
plt.title("Total Revenue by Price Band")
plt.xlabel("Price Band")
plt.ylabel("Total Revenue")
plt.show()

# Category Performance
category_performance = merged_df.groupby('category').agg(
    total_revenue=pd.NamedAgg(column='item_total', aggfunc='sum')
).reset_index().sort_values(by='total_revenue', ascending=False)
print("\nCategory Performance:\n", category_performance)

# Brand Pplt.figure(figsize=(7,5))
sns.barplot(data=price_band_performance, x="price_band", y="total_revenue", palette="coolwarm")
plt.title("Total Revenue by Price Band")
plt.xlabel("Price Band")
plt.ylabel("Total Revenue")
plt.show()
# this dataset only had one brand in future update if you have more barnd use this to analysis
# brand_performance = merged_df.groupby('brand').agg(
#     total_revenue=pd.NamedAgg(column='item_total', aggfunc='sum')
# ).reset_index().sort_values(by='total_revenue', ascending=False)

# print("\nBrand Performance:\n", brand_performance)
plt.figure(figsize=(8,5))
sns.barplot(data=category_performance, x="total_revenue", y="category", palette="cubehelix")
plt.title("Total Revenue by Category")
plt.xlabel("Total Revenue")
plt.ylabel("Category")
plt.show()

# Product Size Performance
size_performance = merged_df.groupby('size').agg(
    total_revenue=pd.NamedAgg(column='item_total', aggfunc='sum'),
    total_quantity=pd.NamedAgg(column='quantity', aggfunc='sum')
).reset_index().sort_values(by='total_revenue', ascending=False)

print("\nSize Performance:\n", size_performance)


plt.figure(figsize=(8,5))
sns.barplot(data=size_performance, x="total_revenue", y="size", palette="viridis")
plt.title("Total Revenue by Size")
plt.xlabel("Total Revenue")
plt.ylabel("Size")
plt.show()

# color preferance
color_performance = merged_df.groupby('color').agg(
    total_revenue=pd.NamedAgg(column='item_total', aggfunc='sum'),
    total_quantity=pd.NamedAgg(column='quantity', aggfunc='sum')
).reset_index().sort_values(by='total_revenue', ascending=False)

print("\nColor Performance:\n", color_performance)

plt.figure(figsize=(8,5))
sns.barplot(data=color_performance, x="total_revenue", y="color", palette="cubehelix")
plt.title("Total Revenue by Color")
plt.xlabel("Total Revenue")
plt.ylabel("Color")
plt.show()

# Price Sensitivity

plt.figure(figsize=(8,6))
sns.scatterplot(data=merged_df, x="unit_price", y="quantity", hue="category", alpha=0.7, palette="Set2")
plt.title("Price vs Quantity Sold")
plt.xlabel("Unit Price")
plt.ylabel("Quantity Sold")
plt.legend(title="Category", bbox_to_anchor=(1.05, 1), loc='upper left')
plt.show()