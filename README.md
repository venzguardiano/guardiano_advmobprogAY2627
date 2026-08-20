# Venz Ygnaz O. Guardiano

## INF231

## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web transactions.

# Lab Activity 4: Discussion

The User Model stores the user information returned by the API, while the UserService handles the API authentication and saves the user's data using SharedPreferences. The Profile Screen gets the saved user through the UserService and uses the User Model to render the user's information.

The updated design pattern follows Model-Service-Screen, where the Model manages the data, the Service handles API requests and saved data, and the Screen displays the data.

The saved user's userId is used to render the correct cart. The Profile Screen gets the user's ID from the User Model and passes it to the CartService, which retrieves and displays the cart belonging to that user.

## Lab Activity Instance
