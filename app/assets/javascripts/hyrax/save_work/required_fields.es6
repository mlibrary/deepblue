export class RequiredFields {
  // Monitors the form and runs the callback if any of the required fields change
  constructor(form, callback) {
    this.form = form
    this.callback = callback
    this.reload()
  }

  get areComplete() {
    var total = 0
    var arrayLength = this.requiredFields.length;
    for (var i = 0; i < arrayLength; i++) {
       if (this.requiredFields[i].type === "radio") {
          total = total + 1
       }
    }

   return this.requiredFields.filter((n, elem) => { return this.isValuePresent(elem) } ).length === total - 1

  }

  totalRadios(elem) {
    if (elem.type === "radio")
    {
      if (elem.checked)
          {return false}
      else
          {return true}
    }
    else
    {    
       return ($(elem).val() === null) || ($(elem).val().length < 1)
    }
  }

  isValuePresent(elem) {
    if (elem.type === "radio")
    {
      if (elem.checked)
          {return false}
      else
          {return true}
    }
    else
    {    
       return ($(elem).val() === null) || ($(elem).val().length < 1)
    }
  }

  // Reassign requiredFields because fields may have been added or removed.
  reload() {
    // ":input" matches all input, select or textarea fields.
    this.requiredFields = this.form.find(':input[required]')
    this.requiredFields.change(this.callback)
  }
}
