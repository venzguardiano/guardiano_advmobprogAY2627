# Venz Ygnaz O. Guardiano

## INF231

## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web transactions.

# Lab Activity 3: Discussion

The Cart Model converts the API's JSON into Cart and CartProduct objects. The Cart Service calls the cart endpoints and returns the parsed data. The Cart Screen calls the service and displays the cart items.

To reach the same detail_screen.dart, the Cart Screen takes the id from the tapped cart item and uses getById (ProductService's getProductById) to fetch the full Product, then passes it to the same ProductDetailsScreen used by the product listing. This is how getById connects a cart item to the detail screen.

The updated design pattern still follows Model-Service-Screen, but now shows one screen (Cart Screen) combining two services (CartService and ProductService) to complete a feature.

## Lab Activity Instance
