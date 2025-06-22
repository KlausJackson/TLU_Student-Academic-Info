# TLU_Student-Academic-Info
Here I provide a class specifically designed for fetching and cleaning data from my school's super messy API. This class handles responses from API requests to fetch schedule, exam schedule, and grades.

## Preview

<style>
  .image-container {
    display: flex;
    justify-content: space-between;
    flex-wrap: wrap;
  }
  .first-row {
    display: flex;
    justify-content: center;
    align-items: center; 
  }
  img {
    max-width: 30%;
    max-height: 80%;
    height: auto;
    margin: 5px;
  }
  .small-div {
    display: flex;
    flex-direction: column; 
    flex: 1;
    margin: 0 5px;
    text-align: center;
  }
  .small-div .imgs {
    display: flex;
    justify-content: center;
  }
</style>

<div class="image-container">
    <div class="first-row">
        <img src="previews/login.png" alt="Login Preview">
        <img src="previews/class_schedule.jpg" alt="Class Schedule">
        <img src="previews/exam_schedule.jpg" alt="Exam Schedule">
    </div>

  <div class="small-div">
    <div class="text">
        <p>This is not my grade</p>
        <p>Attendance tracking for selected subjects after fetching the class schedule; they remain even if you fetch a new class schedule.</p>
    </div>
    <div class="imgs">    
        <img src="previews/grade.jpg" alt="Grade">
        <img src="previews/attendance_tracking.jpg" alt="Attendance Tracking">
    </div>
  </div>
</div>

## Overview
As a student attending Thuy Loi University, you're probably familiar with our school website. It's notoriously slow, primarily because it sends hundreds of requests every time you perform an action. The last time I checked, it generated 134 requests and consumed 70MB of data. Most of the JSON that the server sends back is overwhelming, often containing up to 20,000 lines or even over 1,000,000 lines. In many fields and subfields, you'll find a plethora of null values, duplicated fields, or sometimes both.

![Multiple unnecessary and resource-inefficient API requests](network_requests.png)

In my Flutter app, it sends only the necessary requests. While it still receives the messy JSON, I’ve cleaned it up so that only the relevant fields are displayed.

In this repository, I’m sharing the data-cleaning code with the hope that it will be useful to others who are working on their own applications or tools that utilize our school's API, so you don't have to waste some of your time cleaning the data yourself.
