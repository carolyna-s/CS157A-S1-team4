-- Run this in Workbench to populate empty relation tables from existing data.
-- Safe to run multiple times; INSERT IGNORE skips any duplicates.

INSERT IGNORE INTO Creates (userID, tripID)
SELECT userID, tripID FROM Trip;

INSERT IGNORE INTO Includes_Hotel (tripID, hotelID)
SELECT tripID, hotelID FROM Trip_Hotels;

INSERT IGNORE INTO Includes_Transportation (tripID, transportID)
SELECT tripID, transportID FROM Trip_Transportation;

INSERT IGNORE INTO Makes_Payment (userID, paymentID)
SELECT userID, paymentID FROM Payments;

INSERT IGNORE INTO Pays_For (tripID, paymentID)
SELECT tripID, paymentID FROM Payments;
