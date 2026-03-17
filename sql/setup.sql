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

CREATE TABLE Creates (
    userID INT,
    tripID INT,
    PRIMARY KEY (userID, tripID),
    FOREIGN KEY (userID) REFERENCES Users(userID) ON DELETE CASCADE,
    FOREIGN KEY (tripID) REFERENCES Trip(tripID) ON DELETE CASCADE
);