DROP TABLE IF EXISTS BillWorkSessions;
DROP TABLE IF EXISTS Bills;
DROP TABLE IF EXISTS DocumentKeywords;
DROP TABLE IF EXISTS Documents;
DROP TABLE IF EXISTS WorkSessions;
DROP TABLE IF EXISTS CaseClients;
DROP TABLE IF EXISTS CaseEmployees;
DROP TABLE IF EXISTS Cases;
DROP TABLE IF EXISTS WorksIn;
DROP TABLE IF EXISTS Departments;
DROP TABLE IF EXISTS Employees;
DROP TABLE IF EXISTS Representatives;
DROP TABLE IF EXISTS PhoneNumbers;
DROP TABLE IF EXISTS Persons;
DROP TABLE IF EXISTS Owns;
DROP TABLE IF EXISTS Corporations;
DROP TABLE IF EXISTS Clients;




-- F) Clients
CREATE TABLE Clients(
	ID INT PRIMARY KEY
);


-- A) Corporations
CREATE TABLE Corporations(
	ID INT PRIMARY KEY,
	name VARCHAR NOT NULL,
	address VARCHAR NOT NULL,
	email_address VARCHAR NOT NULL,
	phone_number VARCHAR NOT NULL,

	clientID INT UNIQUE REFERENCES Clients(ID)
);


-- D) Owns (relationship)
CREATE TABLE Owns(
	ownerID INT NOT NULL, -- corporation that owns shares
	ownsID INT NOT NULL, -- the share

	share DECIMAL NOT NULL,
	CHECK (share > 0 AND share <= 100), -- valid percentage (25% would be 25)

	PRIMARY KEY (ownerID, ownsID),
	FOREIGN KEY (ownerID) REFERENCES Corporations(ID),
	FOREIGN KEY (ownsID) REFERENCES Corporations(ID),
	CHECK (ownerID <> ownsID) -- corporation cannot own itself
);


-- B) Persons
CREATE TABLE Persons(
	ID INT PRIMARY KEY,
	name VARCHAR NOT NULL,
	address VARCHAR NOT NULL,
	email_address VARCHAR NOT NULL,

	clientID INT UNIQUE REFERENCES Clients(ID)
);


-- PhoneNumbers (multiple per person)
CREATE TABLE PhoneNumbers(
	personID INT NOT NULL REFERENCES Persons(ID),
	phone_number VARCHAR NOT NULL,
	PRIMARY KEY (personID, phone_number)
);


-- C) Representatives
-- DDL cannot ensure that a corporation has at least one representative
CREATE TABLE Representatives(
	personID INT NOT NULL,
	corporationID INT NOT NULL,
	start_date DATE NOT NULL,

	PRIMARY KEY (personID, corporationID),
	FOREIGN KEY (personID) REFERENCES Persons(ID),
	FOREIGN KEY (corporationID) REFERENCES Corporations(id)
);


-- E) Departments
-- DDL cannot ensure that there is at least 1 and max 4 employees in each department
CREATE TABLE Employees(
	personID INT PRIMARY KEY REFERENCES Persons(ID)
);


CREATE TABLE Departments(
	ID INT PRIMARY KEY,
	name VARCHAR NOT NULL,
	location VARCHAR NOT NULL,
	managerID INT NOT NULL REFERENCES Employees(personID)
);


-- E) Employe works in (relationship table)
CREATE TABLE WorksIn(
	employeeID INT NOT NULL REFERENCES Employees(personID),
	departmentID INT NOT NULL REFERENCES Departments(ID),
	PRIMARY KEY (employeeID, departmentID)
);


-- G)
CREATE TABLE Cases(
	ID INT PRIMARY KEY,
	name VARCHAR NOT NULL UNIQUE, -- unique name per case
	start_date DATE NOT NULL,
	description VARCHAR NOT NULL
);


CREATE TABLE CaseClients(
	caseID INT NOT NULL,
	clientID INT NOT NULL,


	PRIMARY KEY (caseID, clientID),
	FOREIGN KEY (caseID) REFERENCES Cases(ID),
	FOREIGN KEY (clientID) REFERENCES Clients(ID)
);


CREATE TABLE CaseEmployees(
	caseID INT NOT NULL,
	employeeID INT NOT NULL,
	role VARCHAR NOT NULL,
	start_date DATE NOT NULL,


	PRIMARY KEY (caseID, employeeID),
	FOREIGN KEY (caseID) REFERENCES Cases(id),
	FOREIGN KEY (employeeID) REFERENCES Employees(personID)
);


-- H) WorksOn (relationship table)
CREATE TABLE WorkSessions(
	start_time TIMESTAMP NOT NULL,
	description VARCHAR NOT NULL,
	hours NUMERIC NOT NULL,
	CHECK (hours > 0), -- positive hours

	clientID INT NOT NULL,
	employeeID INT NOT NULL,
	caseID INT NOT NULL,

	PRIMARY KEY (caseID, clientID, employeeID, start_time),
    FOREIGN KEY (caseID, clientID) REFERENCES CaseClients(caseID, clientID), -- ensure client is attacheed to a the case
	FOREIGN KEY (employeeID) REFERENCES Employees(personID)
);


-- I. Documents
-- DDL cannot ensure that the document sequence number "must never have gaps".
CREATE TABLE Documents(
	caseID INT NOT NULL,
	sequence_number INT NOT NULL,
	CHECK (sequence_number >= 1), -- starts at 1 (and is positive)

	title VARCHAR NOT NULL,
	content VARCHAR NOT NULL,

	PRIMARY KEY (caseID, sequence_number),
	FOREIGN KEY (caseID) REFERENCES Cases(ID)
);
-- multiple DocutmentKeywords per Document
CREATE TABLE DocumentKeywords(
	caseID INT NOT NULL,
	sequence_number INT NOT NULL,
	keyword VARCHAR NOT NULL,

	PRIMARY KEY (caseID, sequence_number, keyword),
	FOREIGN KEY (caseID, sequence_number) REFERENCES Documents(caseID, sequence_number)
);


-- J) Bill
CREATE TABLE Bills(
	id INT PRIMARY KEY,
	date DATE NOT NULL,

-- total amount needs to match the hours in the workSession (cannot implement in DDL)
	total_amount DECIMAL NOT NULL,
	CHECK (total_amount > 0), -- positive num

	clientID INT NOT NULL,
	FOREIGN KEY (clientID) REFERENCES Clients(id)
);

CREATE TABLE BillWorkSessions(
	billID INT NOT NULL,
	caseID INT NOT NULL,
	clientID INT NOT NULL,
	employeeID INT NOT NULL,
	start_time TIMESTAMP NOT NULL,

	PRIMARY KEY (billID, caseID, clientID, employeeID, start_time),

	FOREIGN KEY (billID) REFERENCES Bills(id),
	FOREIGN KEY (caseID, clientID, employeeID, start_time) REFERENCES WorkSessions(caseID, clientID, employeeID, start_time),
	UNIQUE (caseID, clientID, employeeID, start_time)
);


-- K) [bonus] TRIGGER: client cannot be billed for work done for other clients
DROP FUNCTION IF EXISTS EnforceClientBilling();

CREATE OR REPLACE FUNCTION EnforceClientBilling()
RETURNS TRIGGER AS $$

DECLARE -- declare variables
	BillClientID INT;
	WorkSessionClientID INT;
	
BEGIN
	-- Get the client associated with the bill
	SELECT clientID INTO BillClientID
	FROM Bills
	WHERE id = NEW.billID; -- New refers to the new row being inserted

	-- Get the client from the specific WorkSession being billed
	SELECT clientID INTO WorkSessionClientID
	FROM WorkSessions
	WHERE caseID = NEW.caseID -- New refers to the new row being inserted
		AND employeeID = NEW.employeeID
		AND start_time = NEW.start_time;

	-- Compare clients
	IF BillClientID <> WorkSessionClientID THEN -- If the clients are different
			RAISE EXCEPTION 'Client % cannot be billed for work done for client %',
											BillClientID, WorkSessionClientID
			USING ERRCODE = '45000';
	END IF;


	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER EnforceClientBilling
BEFORE INSERT ON BillWorkSessions
FOR EACH ROW
EXECUTE FUNCTION EnforceClientBilling();