CREATE DATABASE travelog;
USE travelog;

CREATE TABLE Users (
    userID INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    account_created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    account_status ENUM('active', 'suspended', 'pending', 'deactivated') NOT NULL DEFAULT 'pending'
);

CREATE TABLE Traveler (
    userID INT PRIMARY KEY,
    firstName VARCHAR(50) NOT NULL,
    lastName VARCHAR(50) NOT NULL,
    current_location VARCHAR(100),
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE
);

CREATE TABLE Admin (
    userID INT PRIMARY KEY,
    admin_level ENUM('standard', 'senior', 'super') NOT NULL DEFAULT 'standard',
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE
);

CREATE TABLE Company (
    userID INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    business_type ENUM('hotel', 'transportation', 'both') NOT NULL,
    approval_status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    phone VARCHAR(20),
    verification_date DATETIME,
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE
);

CREATE TABLE Trip (
    tripID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT NOT NULL,
    trip_name VARCHAR(100) NOT NULL,
    start_location VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('planned', 'booked', 'cancelled') NOT NULL DEFAULT 'planned',
    time_created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE
);

CREATE TABLE Is_A_Traveller (
    userID INT PRIMARY KEY,
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES Traveler(userID) ON DELETE CASCADE
);

CREATE TABLE Is_A_Company (
    userID INT PRIMARY KEY,
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES Company(userID) ON DELETE CASCADE
);

CREATE TABLE Is_A_Administrator (
    userID INT PRIMARY KEY,
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES Admin(userID) ON DELETE CASCADE
);

CREATE TABLE Hotel_Listing (
    hotelID INT AUTO_INCREMENT PRIMARY KEY,
    company_userID INT,
    hotel_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    description TEXT,
    rating DECIMAL(2,1),
    price_per_night DECIMAL(10,2) NOT NULL,
    availability ENUM('available', 'unavailable') NOT NULL DEFAULT 'available',
    listing_status ENUM('active', 'archived', 'hidden') NOT NULL DEFAULT 'active',
    FOREIGN KEY (company_userID) REFERENCES Company(userID) ON DELETE SET NULL
);

CREATE TABLE Transport_Listing (
    transportID INT AUTO_INCREMENT PRIMARY KEY,
    company_userID INT,
    transport_type ENUM('bus', 'plane', 'train') NOT NULL,
    transport_name VARCHAR(100) NOT NULL,
    departure_location VARCHAR(100) NOT NULL,
    arrival_destination VARCHAR(100) NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    base_cost DECIMAL(10,2) NOT NULL,
    availability ENUM('available', 'unavailable') NOT NULL DEFAULT 'available',
    listing_status ENUM('active', 'archived', 'hidden') NOT NULL DEFAULT 'active',
    last_fetched DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_userID) REFERENCES Company(userID) ON DELETE SET NULL
);

CREATE TABLE Trip_Hotels (
    trip_hotel_sequence_num INT NOT NULL,
    tripID INT NOT NULL,
    hotelID INT NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    booked_price_per_night DECIMAL(10,2) NOT NULL,
    total_cost DECIMAL(10,2) NOT NULL,
    booking_status ENUM('planned', 'booked', 'cancelled', 'refunded') NOT NULL DEFAULT 'planned',
    PRIMARY KEY (trip_hotel_sequence_num, tripID, hotelID),
    FOREIGN KEY (tripID) REFERENCES Trip(tripID) ON DELETE CASCADE,
    FOREIGN KEY (hotelID) REFERENCES Hotel_Listing(hotelID) ON DELETE CASCADE
);

CREATE TABLE Trip_Transportation (
    trip_transport_sequence_num INT NOT NULL,
    tripID INT NOT NULL,
    transportID INT NOT NULL,
    direction ENUM('outbound', 'return') NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    booking_status ENUM('planned', 'booked', 'cancelled', 'refunded') NOT NULL DEFAULT 'planned',
    PRIMARY KEY (trip_transport_sequence_num, tripID, transportID),
    FOREIGN KEY (tripID) REFERENCES Trip(tripID) ON DELETE CASCADE,
    FOREIGN KEY (transportID) REFERENCES Transport_Listing(transportID) ON DELETE CASCADE
);

CREATE TABLE Payments (
    paymentID INT AUTO_INCREMENT PRIMARY KEY,
    tripID INT NOT NULL,
    userID INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('visa', 'mastercard', 'amex', 'paypal') NOT NULL,
    payment_status ENUM('paid', 'declined', 'refunded') NOT NULL DEFAULT 'paid',
    payment_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tripID) REFERENCES Trip(tripID) ON DELETE CASCADE,
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE
);

CREATE TABLE Refunds (
    refundID INT AUTO_INCREMENT PRIMARY KEY,
    paymentID INT NOT NULL,
    refund_amount DECIMAL(10,2) NOT NULL,
    refund_reason TEXT,
    refund_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (paymentID) REFERENCES Payments(paymentID) ON DELETE CASCADE
);

CREATE TABLE Support_Queries (
    queryID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT NOT NULL,
    assigned_admin_userID INT,
    subject VARCHAR(200) NOT NULL,
    message_body TEXT NOT NULL,
    query_status ENUM('open', 'in_progress', 'resolved') NOT NULL DEFAULT 'open',
    created_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_timestamp DATETIME,
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE,
    FOREIGN KEY (assigned_admin_userID) REFERENCES Admin(userID) ON DELETE SET NULL
);

CREATE TABLE Company_Approval_Reviews (
    reviewID INT AUTO_INCREMENT PRIMARY KEY,
    company_userID INT NOT NULL,
    admin_userID INT NOT NULL,
    decision ENUM('approved', 'rejected', 'pending') NOT NULL DEFAULT 'pending',
    review_notes TEXT,
    review_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_userID) REFERENCES Company(userID) ON DELETE CASCADE,
    FOREIGN KEY (admin_userID) REFERENCES Admin(userID) ON DELETE CASCADE
);

-- Junction / Relationship Tables

CREATE TABLE Creates (
    userID INT,
    tripID INT,
    PRIMARY KEY (userID, tripID),
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE,
    FOREIGN KEY (tripID) REFERENCES Trip(tripID) ON DELETE CASCADE
);

CREATE TABLE Posts_Hotel (
    company_userID INT,
    hotelID INT,
    PRIMARY KEY (company_userID, hotelID),
    FOREIGN KEY (company_userID) REFERENCES Company(userID) ON DELETE CASCADE,
    FOREIGN KEY (hotelID) REFERENCES Hotel_Listing(hotelID) ON DELETE CASCADE
);

CREATE TABLE Posts_Transportation (
    company_userID INT,
    transportID INT,
    PRIMARY KEY (company_userID, transportID),
    FOREIGN KEY (company_userID) REFERENCES Company(userID) ON DELETE CASCADE,
    FOREIGN KEY (transportID) REFERENCES Transport_Listing(transportID) ON DELETE CASCADE
);

CREATE TABLE Includes_Hotel (
    tripID INT,
    hotelID INT,
    PRIMARY KEY (tripID, hotelID),
    FOREIGN KEY (tripID) REFERENCES Trip(tripID) ON DELETE CASCADE,
    FOREIGN KEY (hotelID) REFERENCES Hotel_Listing(hotelID) ON DELETE CASCADE
);

CREATE TABLE Includes_Transportation (
    tripID INT,
    transportID INT,
    PRIMARY KEY (tripID, transportID),
    FOREIGN KEY (tripID) REFERENCES Trip(tripID) ON DELETE CASCADE,
    FOREIGN KEY (transportID) REFERENCES Transport_Listing(transportID) ON DELETE CASCADE
);

CREATE TABLE Makes_Payment (
    userID INT,
    paymentID INT,
    PRIMARY KEY (userID, paymentID),
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE,
    FOREIGN KEY (paymentID) REFERENCES Payments(paymentID) ON DELETE CASCADE
);

CREATE TABLE Pays_For (
    tripID INT,
    paymentID INT,
    PRIMARY KEY (tripID, paymentID),
    FOREIGN KEY (tripID) REFERENCES Trip(tripID) ON DELETE CASCADE,
    FOREIGN KEY (paymentID) REFERENCES Payments(paymentID) ON DELETE CASCADE
);

CREATE TABLE Receives_Refund (
    paymentID INT,
    refundID INT,
    PRIMARY KEY (paymentID, refundID),
    FOREIGN KEY (paymentID) REFERENCES Payments(paymentID) ON DELETE CASCADE,
    FOREIGN KEY (refundID) REFERENCES Refunds(refundID) ON DELETE CASCADE
);

CREATE TABLE Submits (
    userID INT,
    queryID INT,
    PRIMARY KEY (userID, queryID),
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE,
    FOREIGN KEY (queryID) REFERENCES Support_Queries(queryID) ON DELETE CASCADE
);

CREATE TABLE Handles (
    admin_userID INT,
    queryID INT,
    PRIMARY KEY (admin_userID, queryID),
    FOREIGN KEY (admin_userID) REFERENCES Admin(userID) ON DELETE CASCADE,
    FOREIGN KEY (queryID) REFERENCES Support_Queries(queryID) ON DELETE CASCADE
);

CREATE TABLE Reviews_Company (
    admin_userID INT,
    reviewID INT,
    PRIMARY KEY (admin_userID, reviewID),
    FOREIGN KEY (admin_userID) REFERENCES Admin(userID) ON DELETE CASCADE,
    FOREIGN KEY (reviewID) REFERENCES Company_Approval_Reviews(reviewID) ON DELETE CASCADE
);

CREATE TABLE Reviewed_For (
    company_userID INT,
    reviewID INT,
    PRIMARY KEY (company_userID, reviewID),
    FOREIGN KEY (company_userID) REFERENCES Company(userID) ON DELETE CASCADE,
    FOREIGN KEY (reviewID) REFERENCES Company_Approval_Reviews(reviewID) ON DELETE CASCADE
);