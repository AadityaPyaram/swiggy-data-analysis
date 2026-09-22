import pandas as pd

df1 = pd.read_excel(r"C:\Users\hp\Desktop\zomato\datasets_xlsx\food.xlsx")
df2 = pd.read_excel(r"C:\Users\hp\Desktop\zomato\datasets_xlsx\menu.xlsx")
df3 = pd.read_excel(r"C:\Users\hp\Desktop\zomato\datasets_xlsx\orders_Type.xlsx")
df4 = pd.read_excel(r"C:\Users\hp\Desktop\zomato\datasets_xlsx\orders.xlsx")
df5 = pd.read_excel(r"C:\Users\hp\Desktop\zomato\datasets_xlsx\restaurant.xlsx")
df6 = pd.read_excel(r"C:\Users\hp\Desktop\zomato\datasets_xlsx\users.xlsx")

df1.shape
df2.shape
df3.shape
df4.shape
df5.shape
df6.shape

df1.to_csv(r"C:\Users\hp\Desktop\zomato\datasets_csv\food.csv", index=False)
df2.to_csv(r"C:\Users\hp\Desktop\zomato\datasets_csv\menu.csv", index=False)
df3.to_csv(r"C:\Users\hp\Desktop\zomato\datasets_csv\orders_type.csv", index=False)
df4.to_csv(r"C:\Users\hp\Desktop\zomato\datasets_csv\orders.csv", index=False)
df5.to_csv(r"C:\Users\hp\Desktop\zomato\datasets_csv\restaurant.csv", index=False)
df6.to_csv(r"C:\Users\hp\Desktop\zomato\datasets_csv\users.csv", index=False)

df1.shape
df2.shape
df3.shape
df4.shape
df5.shape
df6.shape