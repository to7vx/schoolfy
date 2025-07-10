import { onRequest } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getDatabase } from "firebase-admin/database";
import { logger } from "firebase-functions";

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();
const rtdb = getDatabase();

// Auto-cleanup old pickup queue entries
export const cleanupPickupQueue = onRequest(
  { cors: true },
  async (req, res) => {
    try {
      const now = new Date();
      const cutoffTime = new Date(now.getTime() - 24 * 60 * 60 * 1000); // 24 hours ago
      
      // Get all dates in pickup queue
      const queueRef = rtdb.ref('pickupQueue');
      const snapshot = await queueRef.once('value');
      
      if (!snapshot.exists()) {
        res.json({ success: true, message: 'No data to cleanup' });
        return;
      }
      
      const dates = snapshot.val();
      let cleanedCount = 0;
      
      for (const date in dates) {
        const dateObj = new Date(date);
        if (dateObj < cutoffTime) {
          await queueRef.child(date).remove();
          cleanedCount++;
          logger.info(`Cleaned up pickup queue for date: ${date}`);
        }
      }
      
      res.json({ 
        success: true, 
        message: `Cleaned up ${cleanedCount} old pickup queue entries` 
      });
      
    } catch (error) {
      logger.error('Error in cleanupPickupQueue:', error);
      res.status(500).json({ 
        success: false, 
        error: 'Internal server error' 
      });
    }
  }
);

// Update live statistics
export const updateLiveStats = onRequest(
  { cors: true },
  async (req, res) => {
    try {
      const today = new Date().toISOString().split('T')[0];
      const queueRef = rtdb.ref(`pickupQueue/${today}`);
      const snapshot = await queueRef.once('value');
      
      let totalWaiting = 0;
      let totalToday = 0;
      
      if (snapshot.exists()) {
        const pickups = snapshot.val();
        for (const pickupId in pickups) {
          const pickup = pickups[pickupId];
          totalToday++;
          if (pickup.status === 'waiting' || !pickup.status) {
            totalWaiting++;
          }
        }
      }
      
      // Update live stats
      await rtdb.ref('liveStats').set({
        totalWaiting,
        totalToday,
        lastUpdated: new Date().toISOString()
      });
      
      res.json({ 
        success: true, 
        stats: { totalWaiting, totalToday }
      });
      
    } catch (error) {
      logger.error('Error in updateLiveStats:', error);
      res.status(500).json({ 
        success: false, 
        error: 'Internal server error' 
      });
    }
  }
);

// Create admin user
export const createAdminUser = onRequest(
  { cors: true },
  async (req, res) => {
    try {
      const { uid, email, name } = req.body;
      
      if (!uid || !email || !name) {
        res.status(400).json({ 
          success: false, 
          error: 'Missing required fields: uid, email, name' 
        });
        return;
      }
      
      // Create admin user document
      await db.collection('users').doc(uid).set({
        email,
        name,
        role: 'admin',
        createdAt: new Date().toISOString(),
        permissions: {
          manageStudents: true,
          manageGuardians: true,
          viewPickupQueue: true,
          managePickupHistory: true,
          viewAnalytics: true,
          manageSettings: true
        }
      });
      
      logger.info(`Created admin user: ${email}`);
      res.json({ 
        success: true, 
        message: 'Admin user created successfully' 
      });
      
    } catch (error) {
      logger.error('Error in createAdminUser:', error);
      res.status(500).json({ 
        success: false, 
        error: 'Internal server error' 
      });
    }
  }
);

// Backup data
export const backupData = onRequest(
  { cors: true },
  async (req, res) => {
    try {
      const timestamp = new Date().toISOString();
      
      // Backup Firestore collections
      const collections = ['users', 'students', 'schools', 'guardianRequests'];
      const backup: { [key: string]: { [docId: string]: any } } = {};
      
      for (const collectionName of collections) {
        const snapshot = await db.collection(collectionName).get();
        backup[collectionName] = {};
        
        snapshot.forEach(doc => {
          backup[collectionName][doc.id] = doc.data();
        });
      }
      
      // Save backup to Firestore
      await db.collection('backups').doc(timestamp).set({
        data: backup,
        createdAt: timestamp,
        type: 'manual'
      });
      
      res.json({ 
        success: true, 
        message: 'Data backup completed',
        backupId: timestamp
      });
      
    } catch (error) {
      logger.error('Error in backupData:', error);
      res.status(500).json({ 
        success: false, 
        error: 'Internal server error' 
      });
    }
  }
);
