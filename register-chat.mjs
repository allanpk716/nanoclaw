// Register a Telegram chat to the database
import Database from 'better-sqlite3';
import readline from 'readline';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const db = new Database('store/messages.db');

console.log('=== Register Telegram Chat ===\n');

rl.question('Enter Chat ID (e.g., tg:123456789): ', (chatId) => {
  rl.question('Enter Chat Name (e.g., MyChat): ', (chatName) => {
    try {
      const stmt = db.prepare(`
        INSERT OR REPLACE INTO registered_groups
        (jid, name, folder, trigger_pattern, added_at, requires_trigger)
        VALUES (?, ?, ?, ?, ?, ?)
      `);

      stmt.run(
        chatId,              // jid (e.g., tg:123456789)
        chatName,            // name
        'main',              // folder
        '@nex',              // trigger_pattern
        new Date().toISOString(),  // added_at
        0                    // requires_trigger (0 = 不需要触发词)
      );

      console.log('\n✅ Chat registered successfully!');
      console.log(`   Chat ID: ${chatId}`);
      console.log(`   Name: ${chatName}`);
      console.log(`   Trigger: @nex (optional)`);
      console.log('\nYou can now send messages to the bot!');

      // Verify the registration
      const registered = db.prepare('SELECT * FROM registered_groups WHERE jid = ?').get(chatId);
      console.log('\nRegistered group details:');
      console.log(registered);

    } catch (error) {
      console.error('\n❌ Error registering chat:', error.message);
      console.error(error);
    } finally {
      db.close();
      rl.close();
    }
  });
});
