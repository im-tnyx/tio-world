async function testRlsDenial() {
  const url = 'https://oykupyiitspujzpwwvuj.supabase.co/rest/v1';
  const headers = {
    'apikey': 'sb_publishable_pVet6gRi6JRZ-dyxrZtDSg_MAZa9mfq',
    'Authorization': 'Bearer sb_publishable_pVet6gRi6JRZ-dyxrZtDSg_MAZa9mfq',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal'
  };

  // Try unauthenticated insert into users
  const resUsers = await fetch(`${url}/users`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Hacker',
      gender: 'male',
      goals: ['lose_weight'],
      date_of_birth: '2000-01-01',
      height_cm: 175,
      current_weight_kg: 70,
      activity_level: 'active',
      health_conditions: []
    })
  });
  const dataUsers = await resUsers.text();
  console.log('[RLS Test: Unauthenticated write to users] Status:', resUsers.status, dataUsers);

  // Try unauthenticated insert into user_workout_preferences
  const resWorkout = await fetch(`${url}/user_workout_preferences`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      user_id: '00000000-0000-0000-0000-000000000001',
      gym_access: 'gym',
      equipment: [],
      experience_level: 'beginner',
      focus_areas: ['full_body'],
      training_days: ['monday'],
      workout_duration: 'auto',
      workout_split: 'auto'
    })
  });
  const dataWorkout = await resWorkout.text();
  console.log('[RLS Test: Unauthenticated write to user_workout_preferences] Status:', resWorkout.status, dataWorkout);

  // Try unauthenticated insert into user_targets
  const resTargets = await fetch(`${url}/user_targets`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      user_id: '00000000-0000-0000-0000-000000000001',
      daily_steps: 10000,
      sleep_target_minutes: 480,
      sleep_time_minutes: 1380,
      wake_time_minutes: 420,
      water_ml: 2500,
      goal_pace_kg_per_week: 0.5
    })
  });
  const dataTargets = await resTargets.text();
  console.log('[RLS Test: Unauthenticated write to user_targets] Status:', resTargets.status, dataTargets);
}

testRlsDenial().catch(console.error);
