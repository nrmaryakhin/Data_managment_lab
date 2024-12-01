CREATE DATABASE rooms_booking;

CREATE TABLE rooms (
	room_id SERIAL NOT NULL PRIMARY KEY,
 	room_name VARCHAR(100) NOT NULL UNIQUE,
 	theme VARCHAR(50) NOT NULL,
 	difficulty_level INT NOT NULL);

CREATE TABLE clients (
	client_id SERIAL NOT NULL PRIMARY KEY,
	client_name VARCHAR(256) NOT NULL,
	client_phone VARCHAR(12) NOT NULL,
	email VARCHAR(100) NOT NULL);

CREATE TABLE employees (
	employee_id SERIAL NOT NULL PRIMARY KEY,
	employee_name VARCHAR(100) NOT NULL,
	role VARCHAR(20) NOT NULL,
	employee_phone VARCHAR(12) NOT NULL,
	salary INT);

CREATE TABLE prices (
	room_id INT REFERENCES rooms (room_id),
	base_price INT NOT NULL,
	extra_price_per_person INT NOT NULL);

CREATE TABLE bookings (
	booking_id SERIAL NOT NULL PRIMARY KEY,
	client_id INT NOT NULL REFERENCES clients (client_id),
	room_id INT NOT NULL REFERENCES rooms (room_id),
	date DATE NOT NULL,
	total_cost INT NOT NULL);

CREATE TABLE booking_employees (
	booking_id INT NOT NULL REFERENCES bookings (booking_id),
	employee_id INT NOT NULL REFERENCES employees (employee_id));

ALTER TABLE rooms
	ADD CHECK(difficulty_level>=1 AND difficulty_level <=5);

ALTER TABLE employees
	ADD CHECK (salary >= 0);

ALTER TABLE prices
	ADD CHECK (base_price >= 0);

ALTER TABLE prices
	ADD CHECK (extra_price_per_person >= 0);

ALTER TABLE bookings
	ADD CHECK (total_cost >= 0);

CREATE INDEX idx_rooms_name ON rooms(room_name);

CREATE INDEX idx_booking_date ON bookings(date);

ALTER TABLE rooms
	ADD max_capacity INT NOT NULL;

ALTER TABLE rooms
	ADD CHECK(max_capacity >= 0);


CREATE OR REPLACE FUNCTION calculate_total_cost()
RETURNS TRIGGER AS $$
DECLARE
     base_price NUMERIC;
     extra_price_per_person NUMERIC;
     max_capacity INT;
BEGIN
     -- Извлекаем данные о ценах и вместимости из rooms и prices
     SELECT r.max_capacity, p.base_price, p.extra_price_per_person
     INTO max_capacity, base_price, extra_price_per_person
     FROM rooms r
     JOIN prices p ON r.room_id = p.room_id
     WHERE r.room_id = NEW.room_id;

     -- Проверяем разницу между max_capacity и number_of_people
     IF (max_capacity - NEW.number_person) = 0 THEN
         NEW.total_cost := NEW.number_person * base_price;
     ELSE
         NEW.total_cost := (max_capacity * base_price) +
                           ((NEW.number_person - max_capacity) * extra_price_per_person);
     END IF;

     RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_calculate_total_cost
BEFORE INSERT OR UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION calculate_total_cost();
