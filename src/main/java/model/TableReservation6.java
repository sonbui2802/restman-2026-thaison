package model;

import java.time.LocalDateTime;

public class TableReservation6 {
    private int id;
    private LocalDateTime createAt;
    private LocalDateTime arrivalTime;
    private LocalDateTime EndTime;
    private int guestNumber;
    private String contactName;
    private String contactPhone;
    private String contactEmail;
    private String status;
    private String note;
    private Customer6 customer;
    private ReservationDetail6[] reservationDetails;

    public TableReservation6() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public LocalDateTime getCreateAt() { return createAt; }
    public void setCreateAt(LocalDateTime createAt) { this.createAt = createAt; }

    public LocalDateTime getArrivalTime() { return arrivalTime; }
    public void setArrivalTime(LocalDateTime arrivalTime) { this.arrivalTime = arrivalTime; }

    public LocalDateTime getEndTime() { return EndTime; }
    public void setEndTime(LocalDateTime EndTime) { this.EndTime = EndTime; }

    public int getGuestNumber() { return guestNumber; }
    public void setGuestNumber(int guestNumber) { this.guestNumber = guestNumber; }

    public String getContactName() { return contactName; }
    public void setContactName(String contactName) { this.contactName = contactName; }

    public String getContactPhone() { return contactPhone; }
    public void setContactPhone(String contactPhone) { this.contactPhone = contactPhone; }

    public String getContactEmail() { return contactEmail; }
    public void setContactEmail(String contactEmail) { this.contactEmail = contactEmail; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public Customer6 getCustomer() { return customer; }
    public void setCustomer(Customer6 customer) { this.customer = customer; }

    public ReservationDetail6[] getReservationDetails() { return reservationDetails; }
    public void setReservationDetails(ReservationDetail6[] details) { this.reservationDetails = details; }
}

