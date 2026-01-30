const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");

const app = express();
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type']
}));
app.use(express.json());

// � Request Logger
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// �🔌 MongoDB connection
const MONGO_URI = "mongodb+srv://23it007_manthan:Manthan_1543_23it007@campusflow007.fwxtu3d.mongodb.net/campusflow?retryWrites=true&w=majority&appName=CampusFlow007";

mongoose.connect(MONGO_URI, { dbName: 'campusflow' })
    .then(() => {
        console.log("------------------------------------------");
        console.log("✅ CONNECTED TO MONGODB ATLAS");
        console.log("📁 DATABASE: campusflow");
        console.log("------------------------------------------");
    })
    .catch((err) => console.error("❌ Database connection error:", err));

// 📄 Schemas
const AppointmentSchema = new mongoose.Schema({
    studentId: String,
    studentName: String,
    facultyId: String,
    facultyName: String,
    subject: String,
    date: String,
    time: String,
    status: { type: String, default: "Pending" },
    rejectionReason: { type: String, default: "" },
    createdAt: { type: Date, default: Date.now }
});

const UserSchema = new mongoose.Schema({
    uid: String,
    name: String,
    email: String,
    role: String,
    department: { type: String, default: "Computer Science" },
    phone: { type: String, default: "+91 98765 43210" },
    idNumber: { type: String, default: "CF2024001" },
    availability: {
        startHour: { type: Number, default: 9 }, // 9 AM
        endHour: { type: Number, default: 17 },   // 5 PM
        days: { type: [Number], default: [1, 2, 3, 4, 5] }, // Mon-Fri
        enabled: { type: Boolean, default: true }
    },
    notificationsEnabled: { type: Boolean, default: true },
    yearOfStudy: { type: String },
    createdAt: { type: Date, default: Date.now }
});

const Appointment = mongoose.model("Appointment", AppointmentSchema);
const User = mongoose.model("User", UserSchema);

// --- ROUTES ---

// 0. CREATE/UPDATE User
app.post("/users", async (req, res) => {
    console.log("POST /users - body:", req.body);
    try {
        const { uid } = req.body;
        if (!uid) return res.status(400).json({ error: "UID is required" });

        const user = await User.findOneAndUpdate({ uid }, req.body, { upsert: true, new: true, setDefaultsOnInsert: true });
        console.log(`✅ [${new Date().toLocaleTimeString()}] User Updated: ${user.name} | ID: ${user.idNumber} | Role: ${user.role}`);
        res.json(user);
    } catch (err) {
        console.error("Error syncing user:", err);
        res.status(400).json({ error: err.message });
    }
});

// 0.1 GET User Profile
app.get("/users/:uid", async (req, res) => {
    try {
        const user = await User.findOne({ uid: req.params.uid });
        if (user) res.json(user);
        else res.status(404).json({ error: "User not found" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 1. CREATE Appointment
app.post("/appointments", async (req, res) => {
    console.log("POST /appointments - body:", req.body);
    try {
        const appointment = new Appointment(req.body);
        const saved = await appointment.save();
        res.status(201).json(saved);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// 2. READ Appointments
app.get("/appointments", async (req, res) => {
    try {
        const { role, uid } = req.query;
        console.log("GET /appointments - role:", role, "uid:", uid);
        let query = {};
        if (role === 'Faculty') {
            query = { facultyId: uid };
        } else {
            query = { studentId: uid };
        }
        const list = await Appointment.find(query).sort({ createdAt: -1 });
        res.json(list);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 2.1 READ Single Appointment
app.get("/appointments/single/:id", async (req, res) => {
    try {
        const item = await Appointment.findById(req.params.id);
        if (item) res.json(item);
        else res.status(404).json({ error: "Not found" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 3. UPDATE Appointment (Status or details)
app.put("/appointments/:id", async (req, res) => {
    console.log(`📡 [${new Date().toLocaleTimeString()}] PUT /appointments/${req.params.id} - data:`, req.body);
    try {
        const updated = await Appointment.findByIdAndUpdate(
            req.params.id,
            { $set: req.body },
            { new: true }
        );
        console.log(`✅ Appointment updated. Status: ${updated.status} | Reason: ${updated.rejectionReason || 'N/A'}`);
        res.json(updated);
    } catch (err) {
        console.error("Update error:", err);
        res.status(400).json({ error: err.message });
    }
});

// 4. DELETE Appointment
app.delete("/appointments/:id", async (req, res) => {
    console.log("DELETE /appointments - id:", req.params.id);
    try {
        await Appointment.findByIdAndDelete(req.params.id);
        res.json({ message: "Deleted successfully" });
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// 5. Faculty List (Case-Insensitive)
app.get("/faculty", async (req, res) => {
    console.log("GET /faculty - fetching all faculty...");
    try {
        // Find users where role is "Faculty" (case-insensitive)
        const list = await User.find({
            role: { $regex: /^Faculty$/i }
        });
        console.log("Found faculty count:", list.length);
        res.json(list);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.listen(5050, "0.0.0.0", () => {
    console.log("Server running on http://localhost:5050");
});
