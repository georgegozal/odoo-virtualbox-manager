# PyCharm Compound Configuration Setup

## 1. შექმენი 3 კონფიგურაცია:

### Configuration A: "Odoo Debug Listener"
```
Type: Python Remote Debug
Name: Odoo Debug Listener
Host: odoo-vm
Port: 5678

Path mappings:
  Local:  /home/dev/Desktop/Odoo/Odoo11/odoo
  Remote: /mnt/odoo11/odoo
```

### Configuration B: "Odoo Debug Start Script"
```
Type: Python
Name: Odoo Debug Start Script
Script: /home/dev/Desktop/Odoo/Odoo11/virtualbox/odoo-restart.py
Parameters: -d swisscapital --dev xml --debug
Python: /home/dev/Desktop/Odoo/Odoo11/.venv3.7/bin/python3.7
```

### Configuration C: "Odoo Normal Start"
```
Type: Python
Name: Odoo Normal Start
Script: /home/dev/Desktop/Odoo/Odoo11/virtualbox/odoo-restart.py
Parameters: -d swisscapital --dev xml
Python: /home/dev/Desktop/Odoo/Odoo11/.venv3.7/bin/python3.7
```

---

## 2. Compound Configuration (Debug):

```
Type: Compound
Name: 🐛 Odoo Full Debug

Configurations to run:
  1. Odoo Debug Listener (wait until connection)
  2. Odoo Debug Start Script
```

---

## 3. გამოყენება:

### ჩვეულებრივი გაშვება:
```
Configuration dropdown: "Odoo Normal Start"
Click: ▶️ Run
```

### Debug რეჟიმი:
```
Configuration dropdown: "🐛 Odoo Full Debug"
Click: 🐛 Debug
```

**ავტომატურად:**
1. PyCharm გაუშვებს Debug Listener-ს
2. ელოდება 3 წამს
3. გაუშვებს Python სკრიპტს `--debug` ფლაგით
4. Odoo დაუკავშირდება debugger-ს
5. Breakpoint-ებზე გაჩერდება

---

## 4. Breakpoint მაგალითი:

```python
# /home/dev/Desktop/Odoo/Odoo11/odoo/addons/sale/models/sale.py

def action_confirm(self):
    # Debug: დააყენე breakpoint აქ
    for order in self:
        order.state = 'sale'
    return True
```

PyCharm-ში:
- Click line number → Red dot
- Run 🐛 Odoo Full Debug
- Odoo-ში დააჭირე "Confirm" ღილაკს
- PyCharm გაჩერდება ამ ხაზზე!