# SQL Study Notes — Isaiah
Files I worked on and how the SQL works in each one.

---

## 1. dashboard.jsp
**What it does:** Shows the traveler's 5 most recent trips when they log in.

```sql
SELECT tripID, trip_name, start_location, destination, start_date, end_date, status
FROM Trip
WHERE userID = ?
ORDER BY time_created DESC
LIMIT 5
```
- `WHERE userID = ?` — only pulls trips belonging to the logged-in user
- `ORDER BY time_created DESC` — newest trips first
- `LIMIT 5` — only show the 5 most recent so the page isn't too long

---

## 2. register_process.jsp
**What it does:** Creates a new user account. If they picked Traveler it inserts into the Traveler table. If they picked Company it inserts into the Company table.

**Step 1 — Check if username/email already exists:**
```sql
SELECT userID FROM Users WHERE username = ? OR email = ?
```
- If this returns a row, the username or email is taken → redirect with error

**Step 2 — Create the base user account:**
```sql
INSERT INTO Users (email, username, password, account_status)
VALUES (?, ?, ?, 'active')
```
- `account_status = 'active'` is hardcoded so they can log in right away

**Step 3a — If Traveler:**
```sql
INSERT INTO Traveler (userID, firstName, lastName, current_location)
VALUES (?, ?, ?, ?)

INSERT INTO Is_A_Traveller (userID) VALUES (?)
```
- `Is_A_Traveller` is a junction table that marks this user as a traveler

**Step 3b — If Company:**
```sql
INSERT INTO Company (userID, name, business_type, phone, approval_status)
VALUES (?, ?, ?, ?, 'pending')

INSERT INTO Is_A_Company (userID) VALUES (?)
```
- `approval_status = 'pending'` means the admin has to approve them before they can post listings
- `Is_A_Company` is a junction table that marks this user as a company

---

## 3. login_process.jsp
**What it does:** Checks which type of user is logging in and sends them to the right page.

**Check 1 — Is it a Traveler?**
```sql
SELECT u.userID, u.username, t.firstName, t.lastName
FROM Users u JOIN Traveler t ON u.userID = t.userID
WHERE u.username = ? AND u.password = ? AND u.account_status = 'active'
```
- JOINs Users and Traveler tables to confirm this account has a traveler profile
- If found → go to dashboard.jsp

**Check 2 — Is it an Admin?**
```sql
SELECT u.userID, u.username
FROM Users u JOIN Admin a ON u.userID = a.userID
WHERE u.username = ? AND u.password = ? AND u.account_status = 'active'
```
- JOINs Users and Admin tables
- If found → go to admin_dashboard.jsp

**Check 3 — Is it a Company?**
```sql
SELECT u.userID, u.username, c.name, c.approval_status
FROM Users u JOIN Company c ON u.userID = c.userID
WHERE u.username = ? AND u.password = ? AND u.account_status = 'active'
```
- JOINs Users and Company tables
- If found → go to company_dashboard.jsp
- If none of the 3 match → "Invalid username or password"

---

## 4. admin_dashboard.jsp
**What it does:** Shows the admin two lists — companies waiting for approval, and open support queries.

**Get pending companies:**
```sql
SELECT c.userID, c.name, c.business_type, c.phone, u.email
FROM Company c JOIN Users u ON c.userID = u.userID
WHERE c.approval_status = 'pending'
```
- JOINs Company and Users to also get the email (stored in Users, not Company)
- Only shows companies that haven't been approved or rejected yet

**Get open support queries:**
```sql
SELECT sq.queryID, sq.subject, sq.query_status, sq.created_timestamp, u.username
FROM Support_Queries sq JOIN Users u ON sq.userID = u.userID
WHERE sq.query_status != 'resolved'
ORDER BY sq.created_timestamp ASC
```
- JOINs Support_Queries with Users to show who submitted it
- `!= 'resolved'` means show both 'open' and 'in_progress' queries
- `ORDER BY ASC` — oldest queries first so admin handles them in order

---

## 5. handle_query_process.jsp
**What it does:** Admin clicks "in progress" or "resolved" on a query — this updates it in the DB.

**Verify user is an admin:**
```sql
SELECT userID FROM Admin WHERE userID = ?
```
- Safety check — prevents a regular user from hitting this page directly

**Update the query status:**
```sql
-- If marking resolved:
UPDATE Support_Queries
SET query_status = 'resolved', assigned_admin_userID = ?, resolved_timestamp = NOW()
WHERE queryID = ?

-- If marking in progress:
UPDATE Support_Queries
SET query_status = 'in_progress', assigned_admin_userID = ?
WHERE queryID = ?
```
- `NOW()` stamps the exact time it was resolved
- `assigned_admin_userID` records which admin handled it

**Log it in the junction table:**
```sql
INSERT INTO Handles (admin_userID, queryID) VALUES (?, ?)
```
- `Handles` tracks which admin handled which query

---

## 6. cancel_trip_process.jsp
**What it does:** Sets a trip's status to 'cancelled'.

```sql
UPDATE Trip
SET status = 'cancelled'
WHERE tripID = ? AND userID = ? AND status != 'cancelled'
```
- `AND userID = ?` — makes sure you can only cancel YOUR OWN trip
- `AND status != 'cancelled'` — prevents cancelling something already cancelled

---

## 7. company_dashboard.jsp
**What it does:** When a company logs in, re-checks their current approval status and business type.

```sql
SELECT approval_status, business_type FROM Company WHERE userID = ?
```
- Re-fetches every page load so if admin just approved them, they see it immediately
- `business_type` tells the page whether to show the hotel form, transport form, or both

---

## 8. post_hotel_process.jsp
**What it does:** An approved company submits the hotel form — this inserts the listing.

**Insert the hotel listing:**
```sql
INSERT INTO Hotel_Listing
(company_userID, hotel_name, location, description, rating, price_per_night, availability, listing_status, last_fetched)
VALUES (?, ?, ?, ?, ?, ?, 'available', 'active', NOW())
```
- `company_userID` links the listing back to the company that posted it
- `'available'` and `'active'` mean travelers can see and book it immediately
- `NOW()` timestamps when it was posted (used by the cache system)

**Link company to listing (junction table):**
```sql
INSERT INTO Posts_Hotel (company_userID, hotelID) VALUES (?, ?)
```
- `Posts_Hotel` records the relationship between a company and its hotel listings

---

## 9. post_transportation_process.jsp
**What it does:** An approved company submits the transport form — this inserts the listing.

**Insert the transport listing:**
```sql
INSERT INTO Transport_Listing
(company_userID, transport_type, transport_name, departure_location, arrival_destination,
departure_time, arrival_time, base_cost, availability, listing_status, last_fetched)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'available', 'active', NOW())
```
- Same idea as hotel — links to company, marks as active and available immediately

**Link company to listing (junction table):**
```sql
INSERT INTO Posts_Transportation (company_userID, transportID) VALUES (?, ?)
```
- `Posts_Transportation` records the relationship between a company and its transport listings

---

## 10. browse_hotels.jsp (company listings section)
**What it does:** When a traveler opens the browse hotels page, company-posted hotels always show up at the top even without searching.

```sql
SELECT * FROM Hotel_Listing
WHERE company_userID IS NOT NULL
AND listing_status = 'active'
AND last_fetched > DATE_SUB(NOW(), INTERVAL 30 DAY)
ORDER BY price_per_night ASC
```
- `company_userID IS NOT NULL` — only gets company listings, not API results
- `listing_status = 'active'` — only shows live listings
- `DATE_SUB(NOW(), INTERVAL 30 DAY)` — only shows listings posted in the last 30 days
- `ORDER BY price_per_night ASC` — cheapest first

---

## Key Concepts to Know

**JOIN** — combines two tables using a shared column (usually userID or an ID)
- Example: `Users JOIN Traveler ON u.userID = t.userID` pulls data from both tables at once

**WHERE** — filters which rows come back
- Example: `WHERE userID = ?` only gets rows for the logged-in user

**INSERT INTO** — adds a new row to a table

**UPDATE** — changes an existing row

**ORDER BY** — sorts results (ASC = smallest/oldest first, DESC = largest/newest first)

**LIMIT** — caps how many rows come back

**NOW()** — MySQL function that returns the current date and time

**Junction Tables** (Is_A_Traveller, Is_A_Company, Posts_Hotel, Handles, etc.)
- These tables just hold two IDs to represent a relationship between two entities
- Example: `Posts_Hotel(company_userID, hotelID)` means "this company posted this hotel"
