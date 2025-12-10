require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

// Re-create client here to ensure env vars are loaded if verify fails
const supabaseUrl = 'https://xzhmdxtzpuxycvsatjoe.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseServiceKey) {
    console.error("Missing SUPABASE_SERVICE_ROLE_KEY");
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function run() {
    console.log('Updating app_config...');

    const updates = {
        min_version: '9.5.0',
        download_url: 'https://voo-ward-ussd.onrender.com/voo-citizen-v9.5.0.apk',
        updated_at: new Date().toISOString()
    };

    // Try to update existing single row (assuming id=1 commonly, or just the only row)
    // First, get the row to see ID
    const { data: current } = await supabase.from('app_config').select('id').limit(1).single();

    if (current) {
        console.log('Found existing config, updating...');
        const { data, error } = await supabase
            .from('app_config')
            .update(updates)
            .eq('id', current.id)
            .select();

        if (error) console.error('Update Error:', error);
        else console.log('Update Success:', data);
    } else {
        console.log('No config found, inserting...');
        const { data, error } = await supabase
            .from('app_config')
            .insert(updates)
            .select();

        if (error) console.error('Insert Error:', error);
        else console.log('Insert Success:', data);
    }
}

run();
