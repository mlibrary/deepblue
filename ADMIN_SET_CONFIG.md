# Admin Set Workflow Configuration

Complete these steps in the browser after initial setup.
All URLs assume Rails is running on port 3000 with the `/data` root.

## Prerequisites

- Stack is running: `./bin/dev-stack status` should show all services healthy
- You are logged in as an admin at `http://localhost:3000/data/`
  - Login is automatic in development via the `FakeAuthHeader` middleware (uses your `$USER` env var → `gkostin@umich.edu`)

---

## Step 1 — Configure the Default Admin Set

1. Go to your dashboard collections page:
   `http://localhost:3000/data/dashboard/collections`

2. Find the collection named **"DataSet Admin Set"** (the default admin set).

3. Click the **Edit** button (pencil icon) for that collection.

4. On the edit page:
   - Click the **"Allow Everyone to Deposit"** button
   - Under the workflow section, select the **last radio button** → **Mediated Deposit**

5. Save the changes.

---

## Step 2 — Create the Draft Works Admin Set

1. Go to your dashboard collections page:
   `http://localhost:3000/data/dashboard/collections`

2. Click **New Collection** (or **New Admin Set**).

3. Set the title to exactly:
   ```
   Draft works Admin Set
   ```

4. On the edit page for the new collection:
   - Under the workflow section, select the **second radio button** → **Draft**

5. Save the changes.

---

## Verification

After completing both steps, you should have two admin sets visible in your dashboard:

| Name | Deposit Access | Workflow |
|------|---------------|----------|
| DataSet Admin Set | Everyone | Mediated |
| Draft works Admin Set | — | Draft |

---

## Troubleshooting

**Not seeing the collections page?**
- Confirm you are signed in as an admin
- Check that `gkostin@umich.edu` appears in the `admin` section of `config/role_map.yml`
- Restart Rails if you recently changed `role_map.yml`: check logs with `tail -f log/development.log`

**Workflow radio buttons not visible?**
- The workflow options only appear when editing an admin set (not a regular collection)
- Make sure you navigated to an admin set, not a user collection

**Admin set not found?**
- Run the bootstrap command to recreate it:
  ```zsh
  cd "/Users/gkostin/GitHub/mlibrary/deepblue"
  bundle exec rails runner "owner=User.find_by(email: 'gkostin@umich.edu'); admin_set=Hyrax::AdministrativeSet.new(title: ['DataSet Admin Set']); Hyrax::AdminSetCreateService.new(admin_set: admin_set, creating_user: owner, default_admin_set: true).create!" | cat
  ```

