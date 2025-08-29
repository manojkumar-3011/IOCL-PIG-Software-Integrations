from enum import Enum
from PyQt5.QtGui import QColor

class ListedEnumMixin:
    @classmethod
    def list(cls):
        return [member.value for member in cls]
    
    @classmethod
    def short_list(cls):
        return [member.value[0] for member in cls]
    
    @classmethod
    def long_list(cls):
        return [member.value[1] for member in cls]

    @classmethod
    def names(cls):
        return [member.name for member in cls]

class ComputationMethod(ListedEnumMixin, Enum):
    SEQUENTIAL = ("seq", "Sequential")
    MULTI = ("multi", "Multi")
    JOINT = ("joint", "Joint")

    @classmethod
    def from_string(cls, input_string):
        for member in cls:
            if input_string in member.value:
                return member
        raise ValueError(f"Invalid computation method: {input_string}")

    def short_name(self):
        return self.value[0]

    def long_name(self):
        return self.value[1]

# Other Enums (using the mixin)
class GainSetting(ListedEnumMixin, Enum):
    GAIN_16KM = ('1', "16km")
    GAIN_100KM = ('2', "100km")
    GAIN_MANUAL = ('0', "Manual")

    @classmethod
    def from_string(cls, input_string):
        for member in cls:
            if input_string in member.value:
                return member
        raise ValueError(f"Invalid Gain Settings: {input_string}")

    def short_name(self):
        return self.value[0]

    def long_name(self):
        return self.value[1]

class AccuracyMethod(ListedEnumMixin, Enum):
    QUICK_MODE = ('0', 'Quick')
    COMBINED = ('1', "(WIP) Quick+Accuracy")
    ACCURACY_MODE = ('2', "(WIP) Only Accuracy")
    VM_MODE = ('3', '(WIP) VM Mode')

    @classmethod
    def from_string(cls, input_string):
        for member in cls:
            if input_string in member.value:
                return member
        raise ValueError(f"Invalid Accuracy method: {input_string}")

    def short_name(self):
        return self.value[0]

    def long_name(self):
        return self.value[1]
    

class AppStatus(ListedEnumMixin, Enum):
    COMPLETED = ("Completed", QColor("green"))
    FAILED = ("Failed", QColor("red"))
    IN_PROGRESS = ("In-Progress", QColor("yellow"))

    @classmethod
    def from_string(cls, status_string):
        for member in cls:
            if member.value[0] == status_string:
                return member
        raise ValueError(f"Invalid app status: {status_string}")

    def status_name(self):
        return self.value[0]

    def color(self):
        return self.value[1]

# APP_STATUS_COLORS = {"Completed": QColor("green"), "Failed": QColor("red"), "In-Progress": QColor("yellow")}